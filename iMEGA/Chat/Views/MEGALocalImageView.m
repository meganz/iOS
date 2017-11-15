
#import "MEGALocalImageView.h"
#import "UIImage+MNZCategory.h"

@interface MEGALocalImageView ()

@property (nonatomic) CGPoint offset;

@end

@implementation MEGALocalImageView

#pragma mark - MEGAChatVideoDelegate

- (void)onChatVideoData:(MEGAChatSdk *)api chatId:(uint64_t)chatId width:(NSInteger)width height:(NSInteger)height buffer:(NSData *)buffer {
    UIImage *image = [UIImage mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer.bytes withWidth:width withHeight:height];
    self.image = image;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    _offset = [aTouch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.superview];
    [UIView beginAnimations:@"Dragging" context:nil];
    self.frame = CGRectMake(location.x - self.offset.x, location.y - self.offset.y, self.frame.size.width, self.frame.size.height);
    [UIView commitAnimations];
}

@end
