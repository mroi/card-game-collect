/* Implements a NSButton that does not support click-through, when the window is not active. */
/* There should be a way in Cocoa to do this without subclassing, but there is none. */

@interface NoClickThroughButton : NSButton
@end
