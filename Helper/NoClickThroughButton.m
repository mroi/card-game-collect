#import "NoClickThroughButton.h"


@implementation NoClickThroughButton

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return NO;
}

@end
