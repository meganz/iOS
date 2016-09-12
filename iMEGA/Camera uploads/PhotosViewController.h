#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"
#import "MWPhotoBrowser.h"

@interface PhotosViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, MEGARequestDelegate, MEGATransferDelegate, MEGAGlobalDelegate>

@end
