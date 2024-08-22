#import <UIKit/UIKit.h>

#import "DisplayMode.h"

NS_ASSUME_NONNULL_BEGIN

@class MEGAPhotoBrowserViewController, PhotoBrowserDataProvider, PhotoBrowserViewModel, DefaultNodeAccessoryActionDelegate;

typedef NS_ENUM(NSUInteger, MEGAPhotoMode) {
    MEGAPhotoModeThumbnail = 0,
    MEGAPhotoModePreview,
    MEGAPhotoModeOriginal
};

@interface MEGAPhotoBrowserViewController : UIViewController

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode isFromSharedItem:(BOOL)isFromSharedItem presentingNode:(MEGANode *)node;

+ (MEGAPhotoBrowserViewController *)photoBrowserWithMediaNodes:(NSMutableArray<MEGANode *> *)mediaNodesArray api:(MEGASdk *)api displayMode:(DisplayMode)displayMode isFromSharedItem:(BOOL)isFromSharedItem preferredIndex:(NSUInteger)preferredIndex;

+ (MEGAPhotoBrowserViewController *)photoBrowserWithProvider:(PhotoBrowserDataProvider *)provider api:(MEGASdk *)api displayMode:(DisplayMode)displayMode isFromSharedItem:(BOOL)isFromSharedItem;

@property (nonatomic, strong) PhotoBrowserViewModel *viewModel;
@property (nonatomic) MEGASdk *api;
@property (nonatomic) CGRect originFrame;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic) BOOL isFromSharedItem;
@property (nonatomic) NSString *publicLink;
@property (nonatomic) NSString *encryptedLink;
@property (nonatomic) BOOL needsReload;
@property (nonatomic) MEGAHandle chatId;
@property (nonatomic) MEGAHandle messageId;
@property (nonatomic) NSArray *messagesIds;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *centerToolbarItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) PhotoBrowserDataProvider *dataProvider;
@property (nonatomic, strong, nullable) UIView *snackBarContainer;
@property (strong, nonatomic) DefaultNodeAccessoryActionDelegate *defaultNodeAccessoryActionDelegate;

- (void)reloadUI;
- (void)configureNodeIntoImage:(MEGANode *) node nodeIndex:(NSUInteger) index;
- (BOOL)isPreviewingVersion;
- (IBAction)didPressAllMediasButton:(UIBarButtonItem *)sender;
- (void)shareFileLink;
@end

NS_ASSUME_NONNULL_END
