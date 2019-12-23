/* displays the value of a localized enum textually */
@interface TextualEnumTransformer : NSValueTransformer {
	NSArray *enumText;
}
- (id)initWithEnumText:(NSArray *)text;
@end

/* provides a string with proper singular/plural */
@interface QuartettCountTransformer : NSValueTransformer
@end

/* uniquifies an array and sorts the elements by occurence count */
@interface ArrayUniqueTransformer : NSValueTransformer
@end

/* ensures that no null strings are passed to managed object attributes */
/* This transformer is used to preprocess the output of the Combo Box data editor fields.
 * They output nil for empty strings, which feels like a bug to me. */
@interface NotNullTransformer : NSValueTransformer
@end

/* turns mere existence of an object into an integer suitable for a cell's state */
@interface OccurrenceToStateTransformer : NSValueTransformer
@end
