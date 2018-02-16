
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

typedef NS_ENUM(NSUInteger, MEGACameraUploadsState) {
    MEGACameraUploadsStateDisabled,
    MEGACameraUploadsStateUploading,
    MEGACameraUploadsStateCompleted,
    MEGACameraUploadsStateNoInternetConnection,
    MEGACameraUploadsStateEmpty
};

@interface PhotosViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, MEGARequestDelegate, MEGATransferDelegate, MEGAGlobalDelegate>

@end
