#import "PasswordView.h"

#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@implementation PasswordView

- (id)initWithFrame:(CGRect)frame {
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
    self.leftImage = self.leftImage;
    self.topLabelTextKey = self.topLabelTextKey;
}

#pragma mark - Private

- (void)customInit {
    self.customView = [[NSBundle bundleForClass:self.class] loadNibNamed:@"PasswordView" owner:self options:nil].firstObject;
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    self.customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.passwordTextField.delegate = self;
    
    [self configureSecureTextEntry];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:singleTap];
    [self updateAppearance];
}

- (void)configureToggleSecureButton {
    if (self.passwordTextField.secureTextEntry) {
        UIImage *image = [[UIImage megaImageWithNamed:@"showHidePassword"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.toggleSecureButton setImage:image forState: UIControlStateNormal];
        [self setToggleSecureButtonTintColorWithIsActive:NO];
    } else {
        UIImage *image = [[UIImage megaImageWithNamed:@"showHidePassword_active"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
        [self.toggleSecureButton setImage:image forState: UIControlStateNormal];
        [self setToggleSecureButtonTintColorWithIsActive:YES];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [self.passwordTextField becomeFirstResponder];
}

#pragma mark - Public

- (void)configureSecureTextEntry {
    [self configureToggleSecureButton];
    self.toggleSecureButton.hidden = YES;
}

- (void)setErrorState:(BOOL)error {
    NSString *text = error ? LocalizedString(@"passwordWrong", @"Wrong password") : LocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password");
    [self setErrorState:error withText:text];
}

- (void)setErrorState:(BOOL)error withText:(NSString *)text {
    self.topLabel.text = text;
    if (error) {
        self.topLabel.textColor = [self errorTextColor];
        self.passwordTextField.textColor = [self errorTextColor];
    } else {
        self.topLabel.textColor = [self normalLabelColor];
        self.passwordTextField.textColor = [self normalTextColor];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.toggleSecureButton.hidden = NO;
    [self.delegate passwordViewBeginEditing];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.passwordTextField.secureTextEntry = YES;
    self.toggleSecureButton.hidden = YES;
}

#pragma mark - IBActions

- (IBAction)tapToggleSecureTextEntry:(id)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    [self configureToggleSecureButton];
    //This code fix the position of the text field cursor not locating properly when toggle secure text entry
    NSString *tmpString = self.passwordTextField.text;
    self.passwordTextField.text = @" ";
    self.passwordTextField.text = tmpString;
}

#pragma mark - IBInspectables

- (void)setLeftImage:(UIImage *)leftImage {
    _leftImage = leftImage;
    self.leftImageView.image = self.leftImage;
}

- (void)setTopLabelTextKey:(NSString *)topLabelTextKey {
    _topLabelTextKey = topLabelTextKey;
    self.topLabel.text = LocalizedString(topLabelTextKey, @"");
}

@end
