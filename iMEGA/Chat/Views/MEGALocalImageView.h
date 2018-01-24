
#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"


typedef NS_ENUM(NSUInteger, Corner) {
    CornerTopLeft,
    CornerTopRight,
    CornerBottonLeft,
    CornerBottonRight
};

@interface MEGALocalImageView : UIImageView <MEGAChatVideoDelegate>

@property (nonatomic) Corner corner;
@property (nonatomic, setter=setVisibleControls:, getter=areControlsVisible) BOOL visibleControls;

- (void)rotateToLandscape;
- (void)rotateToPortrait;

@end
