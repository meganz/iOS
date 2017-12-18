
#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

@interface ProductDetailViewController : UIViewController

@property (nonatomic, getter=isChoosingTheAccountType) BOOL chooseAccountType;

@property (nonatomic) MEGAAccountType megaAccountType;
@property (nonatomic, strong) NSString *storageString;
@property (nonatomic, strong) NSString *bandwidthString;
@property (nonatomic, strong) NSString *priceMonthString;
@property (nonatomic, strong) NSString *priceYearlyString;
@property (nonatomic, strong) NSString *iOSIDMonthlyString;
@property (nonatomic, strong) NSString *iOSIDYearlyString;

@end
