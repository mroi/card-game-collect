#import "QVPredicateFactory.h"

#import "QVViewHelper.h"


@implementation QVViewHelper

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(scrollToSelection:)
												 name:NSTableViewSelectionDidChangeNotification
											   object:tableView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidBecomeMain:)
												 name:NSWindowDidBecomeMainNotification
											   object:window];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidResignMain:)
												 name:NSWindowDidResignMainNotification
											   object:window];
	
	int i;
	for (i = 1; i < sizeof(qvPredicateNames) / sizeof(qvPredicateNames[0]); i++)
		[[self content] addObserver:self
						 forKeyPath:qvPredicateNames[i]
							options:0
							context:NULL];
	
	[self moveTableToBoundary:statusBar withAnimation:NO];
}

#pragma mark -

- (void)scrollToSelection:(NSNotification *)notification
{
	int selection = [tableView selectedRow];
	if (selection >= 0)
		// This does not support animation right now.
		[[tableView animator] scrollRowToVisible:selection];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[self setIsMainWindow:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	[self setIsMainWindow:NO];
}

#pragma mark -
#pragma mark Panel Show / Hide

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object valueForKeyPath:qvPredicateNames[QVIncompletePredicate]]) {
		[self setFilterText:NSLocalizedString(@"IncompleteFilter", @"filter texts")];
		[self moveTableToBoundary:lowerPanel withAnimation:YES];
	} else if ([object valueForKeyPath:qvPredicateNames[QVNoTotalCountPredicate]]) {
		[self setFilterText:NSLocalizedString(@"NoTotalCountFilter", @"filter texts")];
		[self moveTableToBoundary:lowerPanel withAnimation:YES];
	} else {
		[self moveTableToBoundary:statusBar withAnimation:YES];
	}
}

- (void)moveTableToBoundary:(NSView *)view withAnimation:(BOOL)animate
{
	NSRect frame = [tableScrollView frame];
	CGFloat delta = frame.origin.y - ([view frame].origin.y + [view frame].size.height);
	frame.origin.y -= delta;
	frame.size.height += delta;
	if (animate) {
		[[tableScrollView animator] setFrame:frame];
	} else {
		[tableScrollView setFrame:frame];
		[tableScrollView setNeedsDisplay:YES];
	}
}

@synthesize filterText;
@synthesize isMainWindow;

@end
