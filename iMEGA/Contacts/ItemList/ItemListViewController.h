
#import <UIKit/UIKit.h>
#import "ItemListModel.h"

@protocol ItemListViewControllerDelegate <NSObject>

- (void)removeSelectedItem:(id)item;

@end

@interface ItemListViewController : UIViewController

@property (weak, nonatomic) id<ItemListViewControllerDelegate> itemListDelegate;

- (void)addItem:(ItemListModel *)item;
- (void)removeItem:(ItemListModel *)item;

@end
