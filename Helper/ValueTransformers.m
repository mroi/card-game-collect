#import "ValueTransformers.h"


@implementation TextualEnumTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)initWithEnumText:(NSArray *)text
{
	if ((self = [super init]))
		enumText = [text retain];
	return self;
}

- (id)transformedValue:(id)value
{
	if (value == nil) return nil;
	if ([value respondsToSelector:@selector(unsignedIntValue)])
		return [enumText objectAtIndex:[value unsignedIntValue]];
	else
		[NSException raise:NSInternalInconsistencyException
					format:@"Value (%@) does not respond to -unsignedIntValue.", [value class]];
}

- (void)dealloc
{
	[enumText release];
	enumText = nil;
	[super dealloc];
}

@end


#pragma mark -

@implementation QuartettCountTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	NSUInteger count = 0;
	
	if (value == nil) return nil;
	if ([value respondsToSelector:@selector(unsignedIntegerValue)])
		count = [value unsignedIntegerValue];
	else
		[NSException raise:NSInternalInconsistencyException
					format:@"Value (%@) does not respond to -unsignedIntegerValue.", [value class]];
	
	NSString *number;
	if (count == 1)
		number = NSLocalizedString(@"CardGames1", @"card game grammatical numbers");
	else
		number = NSLocalizedString(@"CardGames+", @"card game grammatical numbers");
	
	return [NSString localizedStringWithFormat:number, value];
}

@end


#pragma mark -

@implementation ArrayUniqueTransformer

static NSInteger occurrenceSort(id object1, id object2, void *context)
{
	NSCountedSet *set = context;
	NSInteger compare = [set countForObject:object1] - [set countForObject:object2];
	if (compare < 0)
		return NSOrderedDescending;
	else if (compare > 0)
		return NSOrderedAscending;
	else
		return NSOrderedSame;
}

+ (Class)transformedValueClass
{
	return [NSArray class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	if (value == nil) return nil;
	if ([value isKindOfClass:[NSArray class]]) {
		NSCountedSet *set = [[[NSCountedSet alloc] initWithArray:value] autorelease];
		NSArray *sorted = [[set allObjects] sortedArrayUsingFunction:occurrenceSort context:set];
		NSMutableArray *result = [[sorted mutableCopy] autorelease];
		[result removeObject:[NSString string]];
		[result removeObject:[NSNull null]];
		return result;
	} else {
		return [NSArray array];
	}
}

@end


#pragma mark -

@implementation NotNullTransformer : NSValueTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	if (value == nil || [value isKindOfClass:[NSNull class]])
		return [NSString string];
	else
		return value;
}

@end


#pragma mark -

@implementation OccurrenceToStateTransformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	if (value == nil)
		return [NSNumber numberWithInteger:NSOffState];
	else
		return [NSNumber numberWithInteger:NSOnState];
}

- (id)reverseTransformedValue:(id)value
{
	return nil;
}

@end
