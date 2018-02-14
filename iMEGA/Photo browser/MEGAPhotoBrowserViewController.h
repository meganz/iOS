
#import <UIKit/UIKit.h>

@class MEGAPhotoBrowserViewController;

typedef NS_ENUM(NSUInteger, MEGAPhotoMode) {
    MEGAPhotoModeThumbnail = 0,
    MEGAPhotoModePreview,
    MEGAPhotoModeFull
};

@protocol MEGAPhotoBrowserDelegate

- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNode:(MEGANode *)node;

@end

@interface MEGAPhotoBrowserViewController : UIViewController

@property (nonatomic) MEGANode *node;
@property (nonatomic) NSArray<MEGANode *> *nodesArray;
@property (nonatomic) MEGASdk *api;
@property (nonatomic) CGRect originFrame;
@property (nonatomic, weak) id<MEGAPhotoBrowserDelegate> delegate;

@end
