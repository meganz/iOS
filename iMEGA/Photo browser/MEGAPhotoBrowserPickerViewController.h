
#import <UIKit/UIKit.h>

@class MEGAPhotoBrowserPickerViewController;

@protocol MEGAPhotoBrowserPickerDelegate

- (void)updateCurrentIndexTo:(NSUInteger)newIndex;
- (void)updateImageView:(UIImageView *)imageView withThumbnailOfNode:(MEGANode *)node;

@end

@interface MEGAPhotoBrowserPickerViewController : UIViewController

@property (nonatomic) NSMutableArray<MEGANode *> *mediaNodes;
@property (nonatomic) id<MEGAPhotoBrowserPickerDelegate> delegate;

@end
