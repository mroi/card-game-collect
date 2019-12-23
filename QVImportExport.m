#import "QVConvertLatex.h"
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

- (void)print
{
	NSPrintPanel *panel = [NSPrintPanel printPanel];
	[panel beginSheetWithPrintInfo:[NSPrintInfo sharedPrintInfo]
					modalForWindow:[[NSApplication sharedApplication] mainWindow]
						  delegate:self
					didEndSelector:@selector(performPrint:returnCode:)
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

static NSString *preamble = @""
"\\documentclass[twocolumn,twoside,10pt,a4paper]{article}\n"
"\\usepackage{%@}\n"
"\\usepackage{ucs}\n"
"\\usepackage[utf8x]{inputenc}\n"
"\\usepackage{palatino}\n"
"\n"
"\\parindent0pt\n"
"\\parskip3ex plus2ex minus0.5ex\n"
"\\columnsep0.4in\n"
"\\addtolength{\\evensidemargin}{-0.5in}\n"
"\\addtolength{\\oddsidemargin}{0.5in}\n"
"\\addtolength{\\topmargin}{-0.8in}\n"
"\\addtolength{\\textheight}{1.5in}\n"
"\\flushbottom\n"
"\\pagestyle{myheadings}\n"
"\n"
"\\setcounter{tocdepth}{1}\n"
"\\setcounter{secnumdepth}{0}\n"
"\\makeatletter\n"
"\\renewcommand{\\l@section}{\\@dottedtocline{0}{0em}{0em}}\n"
"\\renewcommand{\\@pnumwidth}{3em}\n"
"\\renewcommand{\\@tocrmarg}{3em}\n"
"\\makeatother\n"
"\n"
"\\author{%@}\n"
"\\title{%@}\n"
"\n"
"\\begin{document}\n"
"\n"
"\\maketitle\n"
"\\thispagestyle{empty}\n"
"\\tableofcontents\n"
"\\cleardoublepage\n"
"\\raggedright\n"
"\n";

- (void)performPrint:(id)panel returnCode:(int)returnCode
{
	if (!panelConfirmed(panel, returnCode)) return;
	// TODO: print progress panel here?
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// TODO: take this to a temporary directory
	NSString *filename = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"Quartett.tex"];
	[[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
	NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:filename];
	
	if (file) {
		NSString *buffer = [NSString stringWithFormat:preamble,
							NSLocalizedString(@"latexLangCode", @"LaTeX export"),
							latexEscape(NSFullUserName()),
							NSLocalizedString(@"latexTitle", @"LaTeX export")];
		[file writeData:[NSData dataWithBytes:[buffer UTF8String]
									   length:[buffer lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]];
		
		/* We need model knowledge to export the objects to LaTeX. By convention,
		 * the app delegate holds the model code and knows how to do that. Let's check to be sure. */
		id <QVConvertLatex> converter;
		if ([[[NSApplication sharedApplication] delegate] conformsToProtocol:@protocol(QVConvertLatex)]) {
			converter = [[NSApplication sharedApplication] delegate];
		} else {
			// TODO: error handling
		}
		
		NSMutableDictionary *context = [NSMutableDictionary dictionary];
		for (id quartett in [[controller content] sortedArrayUsingDescriptors:[self sortDescriptors]]) {
			buffer = [converter convertToLatex:quartett withContext:context];
			[file writeData:[NSData dataWithBytes:[buffer UTF8String]
										   length:[buffer lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]];
		}
		
		buffer = @"\\end{document}\n";
		[file writeData:[NSData dataWithBytes:[buffer UTF8String]
									   length:[buffer lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]];
	} else {
		// TODO: error handling
	}
	
	[pool drain];
	
	// TODO: continue printing
}

@synthesize sortDescriptors;
@synthesize operationName;
@synthesize progress;

@end
