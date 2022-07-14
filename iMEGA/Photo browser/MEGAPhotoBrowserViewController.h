
#import <UIKit/UIKit.h>

#import "DisplayMode.h"

NS_ASSUME_NONNULL_BEGIN

@class MEGAPhotoBrowserViewController, PhotoBrowserDataProvider;

typedef NS_ENUM(NSUInteger, MEGAPhotoMode) {
    MEGAPhotoModeThumbnail = 0,
    MEGAPhotoModePreview,
    MEGAPhotoModeOriginal
};

@protocol MEGAPhotoBrowserDelegate <NSObject>

@optional
- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNode:(nullable MEGANode *)node;
- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNodeAtIndex:(NSUInteger)index;
- (void)didDismissPhotoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser;

@end

@interface MEGAPhotoBrowserViewController : UIViewController

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode presentingNode:(MEGANode *)node;

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode preferredIndex:(NSUInteger)preferredIndex;

+ (MEGAPhotoBrowserViewController *)photoBrowserWithProvider:(PhotoBrowserDataProvider *)provider api:(MEGASdk *)api displayMode:(DisplayMode)displayMode;

@property (nonatomic) MEGASdk *api;
@property (nonatomic) CGRect originFrame;
@property (nonatomic, weak, nullable) id<MEGAPhotoBrowserDelegate> delegate;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic) NSString *publicLink;
@property (nonatomic) NSString *encryptedLink;
@property (nonatomic) BOOL needsReload;
@property (nonatomic) MEGAHandle chatId;
@property (nonatomic) MEGAHandle messageId;

@end

NS_ASSUME_NONNULL_END
