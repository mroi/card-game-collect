#import "QVImportExport.h"


@implementation QVImportExport

- (void)import
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel beginSheetForDirectory:NSHomeDirectory()
							 file:nil
							types:[NSArray arrayWithObject:@"xml"]
				   modalForWindow:[[NSApplication sharedApplication] mainWindow]
					modalDelegate:self
				   didEndSelector:@selector(performImport:returnCode:)
					  contextInfo:nil];
}

- (void)export
{
	NSArray *desktopFolderList = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
	NSString *desktopFolder = [desktopFolderList count] ? [desktopFolderList objectAtIndex:0] : NSHomeDirectory();
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"xml"];
	[panel beginSheetForDirectory:desktopFolder
							 file:nil
				   modalForWindow:[[NSApplication sharedApplication] mainWindow]
					modalDelegate:self
				   didEndSelector:@selector(performExport:returnCode:)
					  contextInfo:nil];
}

#pragma mark -
#pragma mark Sheet Management

static BOOL panelConfirmed(id panel, int returnCode)
{
	if ([panel respondsToSelector:@selector(close)])
		[panel close];
	return (returnCode == NSOKButton);
}

static void beginSheet(NSWindow *sheet)
{
	if (sheet)
		[[NSApplication sharedApplication] beginSheet:sheet
									   modalForWindow:[[NSApplication sharedApplication] mainWindow]
										modalDelegate:nil
									   didEndSelector:nil
										  contextInfo:nil];
}

static void endSheet(NSWindow *sheet)
{
	if (sheet) {
		[[NSApplication sharedApplication] endSheet:sheet];
		[sheet close];
	}
}

#pragma mark -
#pragma mark Worker Methods

- (void)performImport:(id)panel returnCode:(int)returnCode
{
	if (!panelConfirmed(panel, returnCode)) return;
	[self setOperationName:NSLocalizedString(@"Import", @"import/export operations")];
	[self setProgress:[NSNumber numberWithDouble:0.0]];
	beginSheet(processingSheet);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error = nil;
	NSData *xml = [NSData dataWithContentsOfFile:[panel filename]
										 options:(NSMappedRead | NSUncachedRead)
										   error:&error];
	
	if (xml && !error) {
		NSString *error = nil;
		id objects = [NSPropertyListSerialization propertyListFromData:xml
													  mutabilityOption:NSPropertyListImmutable
																format:NULL
													  errorDescription:&error];
		if (objects && !error && [objects isKindOfClass:[NSArray class]]) {
			/* purge all data and recreate from import */
			[controller removeObjects:[controller content]];
			NSUInteger totalCount = [(NSArray *)objects count];
			NSUInteger currentCount = 0;
			for (id object in (NSArray *)objects) {
				[self setProgress:[NSNumber numberWithDouble:((double)(currentCount++) / (double)totalCount)]];
				[processingSheet displayIfNeeded];
				if ([object isKindOfClass:[NSDictionary class]]) {
					id newObject = [controller newObject];
					[newObject setValuesForKeysWithDictionary:object];
				}
			}
		} else {
			NSLog(@"%@", error);
			// TODO: error handling
			[error release];
		}
	} else {
		NSLog(@"%@", error);
		// TODO: error handling
	}
	
	[pool drain];
	endSheet(processingSheet);
}

- (void)performExport:(id)panel returnCode:(int)returnCode
{
	if (!panelConfirmed(panel, returnCode)) return;
	[self setOperationName:NSLocalizedString(@"Export", @"import/export operations")];
	[self setProgress:[NSNumber numberWithDouble:0.0]];
	beginSheet(processingSheet);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (![[NSFileManager defaultManager] fileExistsAtPath:[panel filename]])
		[[NSFileManager defaultManager] createFileAtPath:[panel filename] contents:nil attributes:nil];
	NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:[panel filename]];
	
	if (file) {
		NSMutableArray *objects = [NSMutableArray array];
		NSUInteger totalCount = [[controller content] count];
		NSUInteger currentCount = 0;
		
		for (id object in [[controller content] sortedArrayUsingDescriptors:[self sortDescriptors]]) {
			[self setProgress:[NSNumber numberWithDouble:((double)(currentCount++) / (double)totalCount)]];
			[processingSheet displayIfNeeded];
			NSMutableDictionary *values = [[[object dictionaryWithValuesForKeys:[object attributeKeys]] mutableCopy] autorelease];
			for (NSString *key in [values keyEnumerator])
				if ([values objectForKey:key] == [NSNull null])
					[values removeObjectForKey:key];
			[objects addObject:values];
		}
		
		NSString *error = nil;
		NSData *xml = [NSPropertyListSerialization dataFromPropertyList:objects
																 format:NSPropertyListXMLFormat_v1_0
													   errorDescription:&error];
		if (error || currentCount != totalCount) {
			NSLog(@"%@", error);
			// TODO: error handling
			[error release];
		}
		[file writeData:xml];
		[file closeFile];
	} else {
		// TODO: error handling
	}
	
	[pool drain];
	endSheet(processingSheet);
}

@synthesize sortDescriptors;
@synthesize operationName;
@synthesize progress;

@end
