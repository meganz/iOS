
#import "MEGALocalImageView.h"
#import "UIImage+MNZCategory.h"

static const CGFloat FIXED_MARGIN = 20;
static const CGFloat TOP_HEIGHT = 85;
static const CGFloat BOTTOM_HEIGHT = 123;

@interface MEGALocalImageView ()

@property (nonatomic) CGPoint offset;

@end

@implementation MEGALocalImageView

- (void)setVisibleControls:(BOOL)visibleControls {
    _visibleControls = visibleControls;
    [self positionViewByCenter:self.center];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
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

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.superview];
    [self positionViewByCenter:location];
}

- (void)positionViewByCenter:(CGPoint)center {
    [UIView beginAnimations:@"Dragging" context:nil];
    
    if (center.x > self.superview.frame.size.width / 2) {
        if (center.y > self.superview.frame.size.height / 2) {
            self.corner = CornerBottonRight;
        } else {
            self.corner = CornerTopRight;
        }
    } else {
        if (center.y > self.superview.frame.size.height / 2) {
            self.corner = CornerBottonLeft;
        } else {
            self.corner = CornerTopLeft;
        }
    }
    
    CGFloat variableHeightMargin = FIXED_MARGIN;
    if (self.areControlsVisible) {
        if (self.corner == CornerTopLeft || self.corner == CornerTopRight) {
            variableHeightMargin += TOP_HEIGHT;
        } else {
            variableHeightMargin += BOTTOM_HEIGHT;
        }
    } else {
        if (self.corner == CornerTopLeft || self.corner == CornerTopRight) {
            variableHeightMargin += (TOP_HEIGHT - 40);
        }
    }
    
    switch (self.corner) {
        case CornerTopLeft:
            self.frame = CGRectMake(FIXED_MARGIN, variableHeightMargin, self.frame.size.width, self.frame.size.height);
            break;
        case CornerTopRight:
            self.frame = CGRectMake(self.superview.frame.size.width - self.frame.size.width - FIXED_MARGIN, variableHeightMargin, self.frame.size.width, self.frame.size.height);
            break;
            
        case CornerBottonLeft:
            self.frame = CGRectMake(FIXED_MARGIN, self.superview.frame.size.height - self.frame.size.height - variableHeightMargin, self.frame.size.width, self.frame.size.height);
            break;
            
        case CornerBottonRight:
            self.frame = CGRectMake(self.superview.frame.size.width - self.frame.size.width - FIXED_MARGIN, self.superview.frame.size.height - self.frame.size.height - variableHeightMargin, self.frame.size.width, self.frame.size.height);
            break;
            
        default:
            break;
    }
    [UIView commitAnimations];
    
}

#pragma mark - MEGAChatVideoDelegate

- (void)onChatVideoData:(MEGAChatSdk *)api chatId:(uint64_t)chatId width:(NSInteger)width height:(NSInteger)height buffer:(NSData *)buffer {
    UIImage *image = [UIImage mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer.bytes withWidth:width withHeight:height];
    self.image = image;
}

@end
