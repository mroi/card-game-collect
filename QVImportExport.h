/* Implements import and export controller logic. All model knowledge is externalized. */

@interface QVImportExport : NSObject {
	IBOutlet NSWindow *processingSheet;
	IBOutlet NSArrayController *controller;
	
	NSArray *sortDescriptors;
	NSString *operationName;
	NSNumber *progress;
}

- (void)import;
- (void)export;
- (void)print;

@property(readwrite, retain) NSArray *sortDescriptors;
@property(readwrite, retain) NSString *operationName;
@property(readwrite, retain) NSNumber *progress;

@end
