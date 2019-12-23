@interface QVViewHelper : NSObjectController {
	IBOutlet NSTableView *tableView;
	IBOutlet NSScrollView *tableScrollView;
	IBOutlet NSBox *lowerPanel;
	IBOutlet NSBox *statusBar;
	IBOutlet NSWindow *window;
	
	NSString *filterText;
	BOOL isMainWindow;
}

- (void)moveTableToBoundary:(NSView *)view withAnimation:(BOOL)animate;

@property(readwrite, retain) NSString *filterText;
@property(readwrite) BOOL isMainWindow;

@end
