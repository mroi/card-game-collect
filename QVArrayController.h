#import "QVImportExport.h"

@interface QVArrayController : NSArrayController {
	IBOutlet QVImportExport *importExportHelper;
	NSArray *sortDescriptors;
	NSMutableDictionary *stickyFilters;
	IBOutlet NSTableView *tableView;
	NSArray *keysDisplayedInTable;
}

- (IBAction)duplicate:(id)sender;
- (IBAction)import:(id)sender;
- (IBAction)export:(id)sender;
- (IBAction)print:(id)sender;

- (IBAction)toggleStickyFilter:(id)sender;
- (NSPredicate *)filterPredicateWithStickyFilter;
- (void)setFilterPredicateWithStickyFilter:(NSPredicate *)predicate;

@property(readonly) QVImportExport *importExportHelper;
@property(readwrite, retain) NSArray *sortDescriptors;
@property(readonly) NSMutableDictionary *stickyFilters;

@end
