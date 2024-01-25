#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoUploadsTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *HEVCLabel;
@property (weak, nonatomic) IBOutlet UILabel *H264Label;

@end

NS_ASSUME_NONNULL_END
