#import <UIKit/UIKit.h>

@class MEGAQLPreviewController;

@interface OfflineViewController : UIViewController

@property (nonatomic, strong) NSIndexPath *peekIndexPath;

@property (assign, nonatomic) BOOL allItemsSelected;
@property (strong, nonatomic) NSString *previewDocumentPath;

@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) NSMutableArray *offlineSortedItems;
@property (nonatomic) NSMutableArray *searchItemsArray;
@property (nonatomic) UISearchController *searchController;

- (NSString *)currentOfflinePath;
- (NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateNavigationBarTitle;
- (BOOL)removeOfflineNodeCell:(NSString *)itemPath;
- (void)setViewEditing:(BOOL)editing;
- (void)itemTapped:(NSString *)name atIndexPath:(NSIndexPath *)indexPath;
- (void)enableButtonsByNumberOfItems;
- (void)enableButtonsBySelectedItems;
- (void)showRemoveAlertWithConfirmAction:(void (^)(void))confirmAction andCancelAction:(void (^ _Nullable)(void))cancelAction;
- (void)setEditMode:(BOOL)editMode;

@end
