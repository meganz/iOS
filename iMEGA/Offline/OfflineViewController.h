#import <UIKit/UIKit.h>

@class MEGAQLPreviewController, MOOfflineNode;

typedef NS_ENUM(NSUInteger, OfflineViewControllerFlavor) {
    AccountScreen = 0,
    HomeScreen,
};

NS_ASSUME_NONNULL_BEGIN

@interface OfflineViewController : UIViewController

@property (nonatomic, strong, nullable) NSIndexPath *peekIndexPath;

@property (nonatomic, assign) BOOL allItemsSelected;
@property (nonatomic, strong, nullable) NSString *previewDocumentPath;

@property (nonatomic, strong, nullable) NSMutableArray *selectedItems;
@property (nonatomic, strong, nullable) NSMutableArray *offlineSortedItems;
@property (nonatomic, strong, nullable) NSMutableArray *offlineSortedFileItems;
@property (nonatomic, strong, nullable) NSMutableArray *searchItemsArray;
@property (nonatomic, strong, nullable) UISearchController *searchController;
@property (nonatomic, assign) OfflineViewControllerFlavor flavor;
@property (nonatomic, readonly) NSString *currentOfflinePath;
@property (nonatomic, strong) NSString *folderPathFromOffline;

- (nullable NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateNavigationBarTitle;
- (BOOL)removeOfflineNodeCell:(NSString *)itemPath;
- (void)setViewEditing:(BOOL)editing;
- (void)itemTapped:(NSString *)name atIndexPath:(NSIndexPath *)indexPath;
- (void)enableButtonsByNumberOfItems;
- (void)enableButtonsBySelectedItems;
- (void)showInfoFilePath:(NSString *)itemPath at:(nullable NSIndexPath *)indexPath from:(UIButton *)sender;
- (void)showRemoveAlertWithConfirmAction:(void (^)(void))confirmAction andCancelAction:(nullable void (^)(void))cancelAction;
- (void)setEditMode:(BOOL)editMode;
- (void)openFileFromWidgetWith:(NSString *)path;
- (NSString *)folderPathFromOffline:(NSString *)absolutePath folder:(NSString *)folderName;

@end

NS_ASSUME_NONNULL_END
