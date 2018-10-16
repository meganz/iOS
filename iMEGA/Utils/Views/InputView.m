
#import "InputView.h"

@implementation InputView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    
    return self;
}

#pragma mark - Private

- (void)customInit {
    self.customView = [NSBundle.mainBundle loadNibNamed:@"InputView" owner:self options:nil].firstObject;
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
}

@end
