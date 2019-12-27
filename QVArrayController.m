#import "QVPredicateFactory.h"

#import "QVArrayController.h"

/* FIXME: If we use the automatic arrangement feature, the first responder handling
 * behaves strangely. Try to edit the order ID and then tab to the next control.
 * The focus gets lost. If we use notifications to rearrange on any change, this
 * all works nicely, however, the problem described in the FIXME inside
 * -automaticRearrangementKeyPaths strikes. This needs attention. Neither solution
 * feels correct right now. */
#define AUTO_ARRANGE 0


@implementation QVArrayController

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]))
		stickyFilters = [[NSMutableDictionary alloc] init];
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	/* update any sorting and arranging potentially changed during NIB loading */
	[self didChangeArrangementCriteria];
	
#if !AUTO_ARRANGE
	/* register for changes in the controlled managed objects */
	NSDictionary *bindingInfo = [self infoForBinding:@"managedObjectContext"];
	id managedObjectContext = [[bindingInfo objectForKey:NSObservedObjectKey] valueForKeyPath:[bindingInfo objectForKey:NSObservedKeyPathKey]];
	if ([managedObjectContext isKindOfClass:[NSManagedObjectContext class]])
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rearrangeObjects)
													 name:NSManagedObjectContextObjectsDidChangeNotification
												   object:managedObjectContext];
#endif
}

#pragma mark -
#pragma mark Actions

- (IBAction)duplicate:(id)sender
{
	for (id object in [self selectedObjects]) {
		NSDictionary *values = [object dictionaryWithValuesForKeys:[object attributeKeys]];
		id newObject = [self newObject];
		[newObject setValuesForKeysWithDictionary:values];
	}
}

- (IBAction)import:(id)sender
{
	[[self importExportHelper] import];
}

- (IBAction)export:(id)sender
{
	[[self importExportHelper] export];
}

@dynamic importExportHelper;

- (QVImportExport *)importExportHelper
{
	if (!importExportHelper)
		[NSBundle loadNibNamed:@"QVImportExport" owner:self];
	[importExportHelper setSortDescriptors:sortDescriptors];
	return importExportHelper;
}

- (IBAction)toggleStickyFilter:(id)sender
{
	NSInteger tag = [sender tag];
	
	if (tag < 0 || tag >= sizeof(qvPredicateNames) / sizeof(qvPredicateNames[0])) return;
	
	NSString *filterName = qvPredicateNames[[sender tag]];
	NSPredicate *filter = [stickyFilters objectForKey:filterName];
	NSDictionary *newFilter = nil;
	
	if (!filter || [filter isEqualTo:[NSNull null]]) {
		/* we need to switch this filter on */
		NSAssert1([[[NSApplication sharedApplication] delegate] conformsToProtocol:@protocol(QVPredicateFactory)],
				  @"application delegate %@ does not conform to the QVPredicateFactory protocol", [NSApp delegate]);
		id <QVPredicateFactory> factory = [[NSApplication sharedApplication] delegate];
		filter = [factory filterPredicate:tag];
		if (filter)
			newFilter = [NSDictionary dictionaryWithObject:filter forKey:filterName];
	}
	
	/* We cannot add the filter to the stickyFilters repository right here in the action method,
	 * because during action handling the framework toggles the state of the menu item
	 * that triggered the action. This is a convenience feature for menu items whose state is bound.
	 * Manipulating stickyFilters would indirectly influence this state via other bindings,
	 * which causes destructive interference with the ongoing state manipulation by the action handling.
	 * Thus, we schedule this manipulation for later, when we have finished handling the action. */
	[[NSRunLoop currentRunLoop] performSelector:@selector(refreshStickyFilter:)
										 target:self
									   argument:newFilter
										  order:0
										  modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

#pragma mark NSMenuValidation Informal Protocol

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(duplicate:))
		if ([self selectionIndex] == NSNotFound) return NO;
	return [super validateMenuItem:menuItem];
}

#pragma mark -
#pragma mark Filtering

@synthesize stickyFilters;

- (void)refreshStickyFilter:(id)newFilter
{
	[stickyFilters removeAllObjects];
	[stickyFilters addEntriesFromDictionary:newFilter];
	/* trigger filtering and clear any other predicates */
	[self setFilterPredicateWithStickyFilter:nil];
}

- (NSPredicate *)filterPredicateWithStickyFilter
{
	return [self filterPredicate];
}

- (void)setFilterPredicateWithStickyFilter:(NSPredicate *)predicate
{
	NSMutableArray *activeFilters = [[[stickyFilters allValues] mutableCopy] autorelease];
	if (predicate)
		[activeFilters addObject:predicate];
	[self setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:activeFilters]];
}

- (void)setFilterPredicate:(NSPredicate *)predicate
{
	if (!predicate)
		/* also flush any sticky predicate */
		[stickyFilters removeAllObjects];
	[self willChangeValueForKey:@"filterPredicateWithStickyFilter"];
	[super setFilterPredicate:predicate];
	[self didChangeValueForKey:@"filterPredicateWithStickyFilter"];
}

#pragma mark -
#pragma mark Sorting

@dynamic sortDescriptors;

- (NSArray *)sortDescriptors
{
	/* always return an empty sort descriptor to the outside world, since we do the sorting ourselves */
	return [NSArray array];
}

- (void)setSortDescriptors:(NSArray *)newSortDescriptors
{
	if (newSortDescriptors != sortDescriptors) {
		[sortDescriptors release];
		sortDescriptors = [newSortDescriptors retain];
		[self didChangeArrangementCriteria];
	}
}

#if AUTO_ARRANGE
/* When any of the keys displayed in the table changes, the sorting might need
 * to be updated, so the controller needs to rearrange. */
- (NSArray *)automaticRearrangementKeyPaths
{
	/* FIXME: This should actually ask the sort descriptor instead of the table view
	 * for the keys to trigger rearrangement. However, we currently use this to
	 * workaround yet another problem: When changing one of the text fields and then
	 * changing a non-focus-taking control (like the list box), the latter will send
	 * its data update, the controller potentially rearranges, overwriting the first
	 * edit in the text field. We illegally use deep view knowledge here: None of the
	 * data edited with non-focus-taking controls is part of the table view. Thus,
	 * only rearranging on keys shown in the table circumvents this problem, as the
	 * critical controls will not trigger a rearrange. This however strongly violates
	 * separation of controller and view and should be changed. I don't know how, though. */
	if (!keysDisplayedInTable) {
		NSMutableArray *keys = [NSMutableArray array];
		for (NSTableColumn *column in [tableView tableColumns]) {
			NSString *keyPath = [[column infoForBinding:@"value"] objectForKey:NSObservedKeyPathKey];
			NSString *key = [[keyPath componentsSeparatedByString:@"."] lastObject];
			if (!key) return nil;
			[keys addObject:key];
		}
		if ([keys count])
			keysDisplayedInTable = [[NSArray alloc] initWithArray:keys];
	}
	return keysDisplayedInTable;
}
#endif

#if 0
- (void)rearrangeObjects
{
	NSLog(@"rearrange requested, %@", [[tableView window] firstResponder]);
	[super rearrangeObjects];
	NSLog(@"rearrange finished, %@", [[tableView window] firstResponder]);
}
#endif

/* The SQLite backend does not support the localizedCaseInsensitiveCompare: selector, so
 * we implement our own array controller which does not pass the sort descriptor down to
 * the managed object context, but instead sorts the data itself afterwards. */
- (NSArray *)arrangeObjects:(NSArray *)objects
{
	return [[super arrangeObjects:objects] sortedArrayUsingDescriptors:sortDescriptors];
}

#pragma mark -

- (void)dealloc
{
	[stickyFilters release];
	[super dealloc];
}

@end
