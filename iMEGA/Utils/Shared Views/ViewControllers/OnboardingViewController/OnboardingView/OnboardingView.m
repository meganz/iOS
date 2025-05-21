#import "OnboardingView.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface OnboardingView ()

@property (nonatomic) UIView *customView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionalLabel;

@end

@implementation OnboardingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
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
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        self.descriptionLabel.textColor = [UIColor mnz_secondaryTextColor];
        self.titleLabel.textColor = [UIColor primaryTextColor];
        
        self.backgroundColor = [UIColor pageBackgroundColor];
    }
}

#pragma mark - Private

- (void)customInit {
    self.customView = [[NSBundle bundleForClass:self.class] loadNibNamed:@"OnboardingView" owner:self options:nil].firstObject;
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    self.customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.titleLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor mnz_secondaryTextColor];
    
    self.backgroundColor = [UIColor pageBackgroundColor];
}

#pragma mark - Setters

- (void)setType:(OnboardingViewType)type {
    _type = type;
    switch (self.type) {
        case OnboardingViewTypeEncryptionInfo:
            self.imageView.image = [UIImage megaImageWithNamed:@"onboarding1_encryption"];
            self.titleLabel.text = LocalizedString(@"You hold the keys", @"Title shown in a page of the on boarding screens explaining that the user keeps the encryption keys");
            self.descriptionLabel.text = LocalizedString(@"Security is why we exist, your files are safe with us behind a well oiled encryption machine where only you can access your files.", @"Description shown in a page of the onboarding screens explaining the encryption paradigm");
            break;
            
        case OnboardingViewTypeChatInfo:
            self.imageView.image = [UIImage megaImageWithNamed:@"onboarding2_chat"];
            self.titleLabel.text = LocalizedString(@"Encrypted chat", @"Title shown in a page of the on boarding screens explaining that the chat is encrypted");
            self.descriptionLabel.text = LocalizedString(@"Fully encrypted chat with voice and video calls, group messaging and file sharing integration with your Cloud Drive.", @"Description shown in a page of the onboarding screens explaining the chat feature");
            break;
            
        case OnboardingViewTypeContactsInfo:
            self.imageView.image = [UIImage megaImageWithNamed:@"onboarding3_contacts"];
            self.titleLabel.text = LocalizedString(@"Create your Network", @"Title shown in a page of the on boarding screens explaining that the user can add contacts to chat and colaborate");
            self.descriptionLabel.text = LocalizedString(@"Add contacts, create a network, colaborate, make voice and video calls without ever leaving MEGA", @"Description shown in a page of the onboarding screens explaining contacts");
            break;
            
        case OnboardingViewTypeCameraUploadsInfo:
            self.imageView.image = [UIImage megaImageWithNamed:@"onboarding4_camera_uploads"];
            self.titleLabel.text = LocalizedString(@"Your Photos in the Cloud", @"Title shown in a page of the on boarding screens explaining that the user can backup the photos automatically");
            self.descriptionLabel.text = LocalizedString(@"Camera Uploads is an essential feature for any mobile device and we have got you covered. Create your account now.", @"Description shown in a page of the onboarding screens explaining the camera uploads feature");
            break;
            
        case OnboardingViewTypePhotosPermission:
            self.imageView.image = [UIImage megaImageWithNamed:@"photosPermission"];
            self.imageView.contentMode = UIViewContentModeCenter;
            self.titleLabel.text = LocalizedString(@"Allow Access to Photos", @"Title label that explains that the user is going to be asked for the photos permission");
            self.descriptionLabel.text = LocalizedString(@"Please give the MEGA App permission to access Photos to share photos and videos.", @"Detailed explanation of why the user should give permission to access to the photos");
            break;
            
        case OnboardingViewTypeMicrophoneAndCameraPermissions:
            self.imageView.image = [UIImage megaImageWithNamed:@"groupChat"];
            self.imageView.contentMode = UIViewContentModeCenter;
            self.titleLabel.text = LocalizedString(@"Enable Microphone and Camera", @"Title label that explains that the user is going to be asked for the microphone and camera permission");
            self.descriptionLabel.text = LocalizedString(@"To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", @"Detailed explanation of why the user should give permission to access to the camera and the microphone");
            break;
     
        case OnboardingViewTypeNotificationsPermission:
            self.imageView.image = [UIImage megaImageWithNamed:@"notificationDevicePermission"];
            self.imageView.contentMode = UIViewContentModeCenter;
            self.titleLabel.text = LocalizedString(@"Enable Notifications", @"Title label that explains that the user is going to be asked for the notifications permission");
            self.descriptionLabel.text = LocalizedString(@"We would like to send you notifications so you receive new messages on your device instantly.", @"Detailed explanation of why the user should give permission to deliver notifications");
            break;
    }
}

@end
