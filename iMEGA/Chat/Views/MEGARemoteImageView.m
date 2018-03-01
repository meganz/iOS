
#import "MEGARemoteImageView.h"
#import "UIImage+MNZCategory.h"

@implementation MEGARemoteImageView

#pragma mark - MEGAChatVideoDelegate

- (void)onChatVideoData:(MEGAChatSdk *)api chatId:(uint64_t)chatId width:(NSInteger)width height:(NSInteger)height buffer:(NSData *)buffer {
    static unsigned long long temp = 0;
    if (temp++ % 100 == 0) {
        UIViewContentMode newContentMode;
        if (self.superview.frame.size.width > self.superview.frame.size.height) {
            if (width > height) {
                newContentMode = UIViewContentModeScaleAspectFill;
            } else {
                newContentMode = UIViewContentModeScaleAspectFit;
            }
        } else {
            if (width > height) {
                newContentMode = UIViewContentModeScaleAspectFit;
            } else {
                newContentMode = UIViewContentModeScaleAspectFill;
            }
        }
        
        if (newContentMode != self.contentMode) {
            [UIView transitionWithView:self duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                self.contentMode = newContentMode;
            } completion:nil];
        }
        
    }
    
    UIImage *image = [UIImage mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer.bytes withWidth:width withHeight:height];
    self.image = image;
}

@end
