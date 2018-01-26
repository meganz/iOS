#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"
#import "MWPhotoBrowser.h"

typedef NS_ENUM(NSUInteger, MEGACameraUploadsState) {
    MEGACameraUploadsStateDisabled,
    MEGACameraUploadsStateUploading,
    MEGACameraUploadsStateCompleted,
    MEGACameraUploadsStateDisconnected,
    MEGACameraUploadsStateEmpty
};

@interface PhotosViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, MEGARequestDelegate, MEGATransferDelegate, MEGAGlobalDelegate>

@end
