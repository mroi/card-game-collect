/* The model and coordinating controller of the application.
 * This is the only class that knows details about the quartetts being managed,
 * how they are sorted and categorized. It also manages the permanent storage
 * of the model data. */

#import "QVPredicateFactory.h"

@interface QuartettVerwaltung : NSObject <QVPredicateFactory> {
    NSManagedObjectContext *managedObjectContext;
	NSArray *sortDescriptors;
	NSDictionary *enumAttributeLocalizations;
}

- (IBAction)save:(id)sender;

@property(readonly) NSManagedObjectContext *managedObjectContext;
@property(readwrite, retain) NSArray *sortDescriptors;
@property(readonly) NSDictionary *enumAttributeLocalizations;

@end
