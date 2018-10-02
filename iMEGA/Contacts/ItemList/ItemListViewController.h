
#import <UIKit/UIKit.h>
#import "ItemListModel.h"

@protocol ItemListViewControllerProtocol <NSObject>

- (void)removeSelectedItem:(id)item;

@end

@interface ItemListViewController : UIViewController

@property (weak, nonatomic) id<ItemListViewControllerProtocol> itemListDelegate;

- (void)addItem:(ItemListModel *)item;
- (void)removeItem:(ItemListModel *)item;

@end
