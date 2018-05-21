
#import <UIKit/UIKit.h>

@protocol UsersListViewControllerProtocol <NSObject>

- (void)removeSelectedUser:(MEGAUser *)user;

@end

@interface UsersListViewController : UIViewController

@property (weak, nonatomic) id<UsersListViewControllerProtocol> userListDelegate;

- (void)addUser:(MEGAUser *)user;
- (void)removeUser:(MEGAUser *)user;

@end
