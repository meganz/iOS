
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MEGAPhotoMode) {
    MEGAPhotoModeThumbnail = 0,
    MEGAPhotoModePreview,
    MEGAPhotoModeFull
};

@interface MEGAPhotoBrowserViewController : UIViewController

@property (nonatomic) MEGANode *node;
@property (nonatomic) NSArray<MEGANode *> *nodesArray;
@property (nonatomic) MEGASdk *api;
@property (nonatomic) CGRect originFrame;

@end
