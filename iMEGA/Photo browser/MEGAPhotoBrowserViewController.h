
#import <UIKit/UIKit.h>

#import "DisplayMode.h"

@class MEGAPhotoBrowserViewController;

typedef NS_ENUM(NSUInteger, MEGAPhotoMode) {
    MEGAPhotoModeThumbnail = 0,
    MEGAPhotoModePreview,
    MEGAPhotoModeOriginal
};

@protocol MEGAPhotoBrowserDelegate

- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNode:(MEGANode *)node;
- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser willDismissWithNode:(MEGANode *)node;

@end

@interface MEGAPhotoBrowserViewController : UIViewController

@property (nonatomic) MEGANode *node;
@property (nonatomic) NSArray<MEGANode *> *nodesArray;
@property (nonatomic) MEGASdk *api;
@property (nonatomic) CGRect originFrame;
@property (nonatomic, weak) id<MEGAPhotoBrowserDelegate> delegate;
@property (nonatomic) DisplayMode displayMode;

@end
