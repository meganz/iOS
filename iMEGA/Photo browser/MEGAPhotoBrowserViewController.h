
#import <UIKit/UIKit.h>

#import "DisplayMode.h"

@class MEGAPhotoBrowserViewController;

typedef NS_ENUM(NSUInteger, MEGAPhotoMode) {
    MEGAPhotoModeThumbnail = 0,
    MEGAPhotoModePreview,
    MEGAPhotoModeOriginal
};

@protocol MEGAPhotoBrowserDelegate <NSObject>

@optional
- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNode:(MEGANode *)node;
- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNodeAtIndex:(NSUInteger)index;
- (void)didDismissPhotoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser;

@end

@interface MEGAPhotoBrowserViewController : UIViewController

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode presentingNode:(MEGANode *)node preferredIndex:(NSUInteger)preferredIndex;

@property (nonatomic) NSMutableArray<MEGANode *> *mediaNodes;
@property (nonatomic) NSUInteger preferredIndex;

@property (nonatomic) MEGASdk *api;
@property (nonatomic) CGRect originFrame;
@property (nonatomic, weak) id<MEGAPhotoBrowserDelegate> delegate;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic) NSString *publicLink;
@property (nonatomic) NSString *encryptedLink;
@property (nonatomic) BOOL needsReload;

@end
