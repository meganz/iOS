
#import "MEGALocalImageView.h"
#import "UIImage+MNZCategory.h"

static const CGFloat FIXED_MARGIN = 20;
static const CGFloat TOP_HEIGHT = 85;
static const CGFloat BOTTOM_HEIGHT = 210;

@interface MEGALocalImageView ()

@property (nonatomic) CGPoint offset;
@property (nonatomic) NSInteger customWidth;
@property (nonatomic) NSInteger customHeight;

@end

@implementation MEGALocalImageView

- (void)setVisibleControls:(BOOL)visibleControls {
    _visibleControls = visibleControls;
    if (self.userInteractionEnabled) {
        [self positionViewByCenter:self.center];
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    _offset = [aTouch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.superview];
    [UIView beginAnimations:@"Dragging" context:nil];
    self.center = CGPointMake(location.x - self.offset.x + self.frame.size.width / 2, location.y - self.offset.y + self.frame.size.height / 2);
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

    CGPoint point = [self startingPoint];
    self.center = CGPointMake(point.x + self.frame.size.width / 2, point.y + self.frame.size.height / 2);
    [UIView commitAnimations];
    
}

- (void)rotate {
    [UIView animateWithDuration:0.5f animations:^{
        self.customWidth = self.frame.size.height;
        self.customHeight = self.frame.size.width;
        CGPoint point = [self startingPoint];
        self.frame = CGRectMake(point.x, point.y, self.customWidth, self.customHeight);
    }];
}

- (void)remoteVideoEnable:(BOOL)enable {
    if (enable) {
        self.autoresizingMask = UIViewAutoresizingNone;
        [UIView animateWithDuration:0.5f animations:^{
            BOOL portrait = [[UIScreen mainScreen] bounds].size.height > [[UIScreen mainScreen] bounds].size.width;
            if (portrait) {
                self.customHeight = self.superview.frame.size.height * 20 / 100;
                self.customWidth = self.customHeight * 3 / 4;
            } else {
                self.customWidth = self.superview.frame.size.width * 20 / 100;
                self.customHeight = self.customWidth * 3 / 4;
            }
            CGPoint point = [self startingPoint];
            self.frame = CGRectMake(point.x, point.y, self.customWidth, self.customHeight);
        }];
    } else {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [UIView animateWithDuration:0.5f animations:^{
            self.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height);
        }];
    }
}

- (CGFloat)variableHeightMargin {
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
    return variableHeightMargin;
}

- (CGPoint)startingPoint {
    CGFloat variableHeightMargin = [self variableHeightMargin];
    CGFloat x,y;
    
    CGFloat iPhoneXOffset = 0.0f;
    if ([[UIDevice currentDevice] iPhoneX] && [[UIScreen mainScreen] bounds].size.height < [[UIScreen mainScreen] bounds].size.width) {
        // Landscape
        iPhoneXOffset = 30.0f;
    }
    switch (self.corner) {
        case CornerTopLeft:
            x = FIXED_MARGIN + iPhoneXOffset;
            y = variableHeightMargin;
            break;
        case CornerTopRight:
            x = self.superview.frame.size.width - self.customWidth - FIXED_MARGIN - iPhoneXOffset;
            y = variableHeightMargin;
            break;
            
        case CornerBottonLeft:
            x = FIXED_MARGIN + iPhoneXOffset;
            y = self.superview.frame.size.height - self.customHeight - variableHeightMargin;
            break;
            
        case CornerBottonRight:
            x = self.superview.frame.size.width - self.customWidth - FIXED_MARGIN - iPhoneXOffset;
            y = self.superview.frame.size.height - self.customHeight - variableHeightMargin;
            break;
            
        default:
            break;
    }
    
    CGPoint point = CGPointMake(x, y);
    return point;
}

#pragma mark - MEGAChatVideoDelegate

- (void)onChatVideoData:(MEGAChatSdk *)api chatId:(uint64_t)chatId width:(NSInteger)width height:(NSInteger)height buffer:(NSData *)buffer {
    UIImage *image = [UIImage mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer.bytes withWidth:width withHeight:height];
    self.image = image;
}

@end
