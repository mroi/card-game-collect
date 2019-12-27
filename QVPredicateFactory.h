typedef enum { QVNoPredicate, QVIncompletePredicate, QVNoTotalCountPredicate } QVPredicateType;

static NSString *qvPredicateNames[] = {
	@"none",
	@"incomplete",
	@"noTotalCount"
};

@protocol QVPredicateFactory
- (NSPredicate *)filterPredicate:(QVPredicateType)type;
@end
