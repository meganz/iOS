
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FeedbackFeeling) {
    FeedbackFeelingHappy = 0,
    FeedbackFeelingConfuse,
    FeedbackFeelingUnhappy,
    FeedbackFeelingNone
};

@interface FeedbackTableViewController : UITableViewController

@property (nonatomic, assign) FeedbackFeeling feeling;

@end
