
#import "InputView.h"

#import "UIColor+MNZCategory.h"

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

#pragma mark - Public

- (void)setErrorState:(BOOL)error withText:(NSString *)text {
    self.topLabel.text = text;
    if (error) {
        self.topLabel.textColor = UIColor.mnz_redError;
        self.inputTextField.textColor = UIColor.mnz_redError;
    } else {
        self.topLabel.textColor = UIColor.mnz_gray999999;
        self.inputTextField.textColor = UIColor.blackColor;
    }
}

@end
