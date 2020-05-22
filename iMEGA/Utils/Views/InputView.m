
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

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    [self customInit];
    [self.customView prepareForInterfaceBuilder];
    // Trigger the setters:
    self.iconImage = self.iconImage;
    self.topLabelTextKey = self.topLabelTextKey;
}

#pragma mark - Private

- (void)customInit {
    self.customView = [[NSBundle bundleForClass:self.class] loadNibNamed:@"InputView" owner:self options:nil].firstObject;
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    self.customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:singleTap];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [self.inputTextField becomeFirstResponder];
}

#pragma mark - Public

- (void)setErrorState:(BOOL)error withText:(NSString *)text {
    self.topLabel.text = text;
    if (error) {
        self.topLabel.textColor = UIColor.mnz_redError;
        self.inputTextField.textColor = UIColor.mnz_redError;
    } else {
        self.topLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
        self.inputTextField.textColor = UIColor.mnz_label;
    }
}

- (void)updateAppearance {
    CALayer *topBorderLayer = CALayer.new;
    topBorderLayer.frame = CGRectMake(0, 0, self.frame.size.width, 0.5);
    topBorderLayer.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection].CGColor;
    [self.customView.layer addSublayer:topBorderLayer];

    CALayer *bottomBorderLayer = CALayer.new;
    bottomBorderLayer.frame = CGRectMake(0, self.customView.frame.size.height, self.frame.size.width, 0.5);
    bottomBorderLayer.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection].CGColor;
    [self.customView.layer addSublayer:bottomBorderLayer];
    
    self.iconImageView.tintColor = self.topLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    self.inputTextField.textColor = UIColor.mnz_label;
    self.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
}

#pragma mark - IBInspectables

- (void)setIconImage:(UIImage *)iconImage {
    _iconImage = iconImage;
    self.iconImageView.image = self.iconImage;
}

- (void)setTopLabelTextKey:(NSString *)topLabelTextKey {
    _topLabelTextKey = topLabelTextKey;
#ifdef TARGET_INTERFACE_BUILDER
    self.topLabel.text = [[NSBundle bundleForClass:self.class] localizedStringForKey:self.topLabelTextKey value:nil table:nil];
#else
    self.topLabel.text = AMLocalizedString(self.topLabelTextKey, nil);
#endif
}

@end
