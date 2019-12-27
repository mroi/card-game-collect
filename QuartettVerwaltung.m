#import "ValueTransformers.h"

#import "QuartettVerwaltung.h"


@implementation QuartettVerwaltung

- (id)init
{
	if ((self = [super init])) {
		/* application support folder */
		NSArray *applicationSupportFolderList = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString *applicationSupportFolder = [applicationSupportFolderList count] ? [applicationSupportFolderList objectAtIndex:0] : NSTemporaryDirectory();
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Quartetts"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportFolder isDirectory:NULL])
			[[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportFolder attributes:nil];
		
		/* collect object model */
		NSArray *allBundles = [NSArray arrayWithObject:[NSBundle mainBundle]];
		NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:allBundles];
		/* Work around an Xcode data modeler bug:
		 * It is not possible to make a string attribute non-optional and set an empty string as the default value.
		 * This is because you cannot type an empty string in a text box...
		 * The workaround is to iterate over all attributes and programmatically set the default accordingly */
		for (NSEntityDescription *entity in managedObjectModel)
			for (NSPropertyDescription *property in entity)
				if ([property isKindOfClass:[NSAttributeDescription class]]) {
					NSAttributeDescription *attribute = (NSAttributeDescription *)property;
					if ([attribute attributeType] == NSStringAttributeType && ![attribute isOptional] && ![attribute defaultValue])
						[attribute setDefaultValue:[NSString string]];
				}
		
		/* create persistent store coordinator */
		NSURL *url = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"Collection.sqlite"]];
		NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
		NSError *error = nil;
		if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													  configuration:nil
																URL:url
															options:nil
															  error:&error])
			[[NSApplication sharedApplication] presentError:error];  // TODO: error handling
		
		/* finally create managed object context */
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
		
		/* initialize sort descriptors */
		NSSortDescriptor *publisherSort = [[[NSSortDescriptor alloc] initWithKey:@"publisher"
																	   ascending:YES
																		selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		NSSortDescriptor *orderIdSort   = [[[NSSortDescriptor alloc] initWithKey:@"orderID"
																	   ascending:YES
																		selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		NSSortDescriptor *nameSort      = [[[NSSortDescriptor alloc] initWithKey:@"name"
																	   ascending:YES
																		selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		NSSortDescriptor *yearSort      = [[[NSSortDescriptor alloc] initWithKey:@"year" ascending:YES] autorelease];
		NSSortDescriptor *totalSort     = [[[NSSortDescriptor alloc] initWithKey:@"totalCardsCount" ascending:YES] autorelease];
		NSSortDescriptor *stateSort     = [[[NSSortDescriptor alloc] initWithKey:@"state" ascending:NO] autorelease];
		NSSortDescriptor *missingSort   = [[[NSSortDescriptor alloc] initWithKey:@"missingCardsCount" ascending:YES] autorelease];
		NSSortDescriptor *boxSort       = [[[NSSortDescriptor alloc] initWithKey:@"hasBox" ascending:NO] autorelease];
		sortDescriptors = [[NSArray arrayWithObjects:publisherSort, orderIdSort, nameSort, yearSort, totalSort, stateSort, missingSort, boxSort, nil] retain];
		
		/* initialize enum localizations */
		NSMutableDictionary *enumAttributeLocalizationsMutable = [[NSMutableDictionary alloc] init];
		[enumAttributeLocalizationsMutable setObject:[NSArray arrayWithObjects:
													  NSLocalizedString(@"enumKind0", @"values of the 'kind' enum"),
													  NSLocalizedString(@"enumKind1", @"values of the 'kind' enum"),
													  NSLocalizedString(@"enumKind2", @"values of the 'kind' enum"),
													  NSLocalizedString(@"enumKind3", @"values of the 'kind' enum"),
													  nil]
											  forKey:@"kind"];
		[enumAttributeLocalizationsMutable setObject:[NSArray arrayWithObjects:
													  NSLocalizedString(@"enumState0", @"values of the 'state' enum"),
													  NSLocalizedString(@"enumState1", @"values of the 'state' enum"),
													  NSLocalizedString(@"enumState2", @"values of the 'state' enum"),
													  NSLocalizedString(@"enumState3", @"values of the 'state' enum"),
													  nil]
											  forKey:@"state"];
		enumAttributeLocalizations = enumAttributeLocalizationsMutable;
		
		/* register transformers based on the localizations of the textual values of the enum attributes */
		for (NSString *attribute in [[self enumAttributeLocalizations] keyEnumerator]) {
			NSArray *enumText = [[self enumAttributeLocalizations] objectForKey:attribute];
			TextualEnumTransformer *textualEnumTransformer = [[TextualEnumTransformer alloc] initWithEnumText:enumText];
			NSString *transformerName = [NSString stringWithFormat:@"Textual%@Transformer", [attribute capitalizedString]];
			[NSValueTransformer setValueTransformer:textualEnumTransformer forName:transformerName];
		}
	}
	return self;
}

@synthesize managedObjectContext;
@synthesize sortDescriptors;
@synthesize enumAttributeLocalizations;

#pragma mark -
#pragma mark Actions

- (IBAction)save:(id)sender
{
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error])
		[[NSApplication sharedApplication] presentError:error];  // TODO: error handling
}

#pragma mark QVPredicateFactory Formal Protocol

- (NSPredicate *)filterPredicate:(QVPredicateType)type
{
	static NSPredicate *incomplete = nil;
	static NSPredicate *noTotalCount = nil;
	
	switch (type) {
		case QVNoPredicate:
			return nil;
		case QVIncompletePredicate:
			if (!incomplete)
				incomplete = [[NSPredicate predicateWithFormat:@"missingCardsCount > 0"] retain];
			return incomplete;
		case QVNoTotalCountPredicate:
			if (!noTotalCount)
				noTotalCount = [[NSPredicate predicateWithFormat:@"totalCardsCount = NULL"] retain];
			return noTotalCount;
	}
}

#pragma mark -
#pragma mark NSMenuValidation Informal Protocol

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(save:))
		if (![[self managedObjectContext] hasChanges]) return NO;
	return YES;
}

#pragma mark NSWindow Delegates

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [[self managedObjectContext] undoManager];
}

#pragma mark NSApplication Delegates

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSApplicationTerminateReply reply = NSTerminateCancel;
	
	if ([[self managedObjectContext] commitEditing]) {
		NSError *error = nil;
		if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error])
			[sender presentError:error];  // TODO: error handling
		else
			reply = NSTerminateNow;
	} else {
		// TODO: error handling
	}
	
	return reply;
}

#pragma mark -

- (void)dealloc
{
	[managedObjectContext release];
	managedObjectContext = nil;
	[sortDescriptors release];
	sortDescriptors = nil;
	[enumAttributeLocalizations release];
	enumAttributeLocalizations = nil;
	
	[super dealloc];
}

@end
