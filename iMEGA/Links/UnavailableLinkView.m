#import "UnavailableLinkView.h"

#import "MEGA-Swift.h"

@implementation UnavailableLinkView

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self updateAppearance];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    
    self.firstTextLabel.textColor = self.secondTextLabel.textColor = self.thirdTextLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}

- (void)showTerms {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://mega.nz/terms"] options:@{} completionHandler:nil];
}

- (void)resetLabels {
    self.firstTextLabel.text = @"";
    self.secondTextLabel.text = @"";
    self.thirdTextLabel.text = @"";
}

- (void)configureDescriptionByUserETDSuspension {
    NSString *text = AMLocalizedString(@"This link is unavailable as the user’s account has been closed for gross violation of MEGA’s [A]Terms of Service[/A].", @"Stand-alone error message shown to users who attempt to load/access a link where the user has been suspended/taken-down due to severe violation of our terms of service.");
    NSRange r1 = [text rangeOfString:@"[A]"];
    NSRange r2 = [text rangeOfString:@"[/A]"];
    NSRange range = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
    NSString *termsString = [text substringWithRange:range];
    text = text.mnz_removeWebclientFormatters;
    NSMutableAttributedString *attributedText = [NSMutableAttributedString.alloc initWithString:text];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor mnz_redForTraitCollection:self.traitCollection] range:[text rangeOfString:termsString]];
    [self.descriptionLabel addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showTerms)]];
    self.descriptionLabel.userInteractionEnabled = YES;
    self.descriptionLabel.attributedText = attributedText;
    [self resetLabels];
}

- (void)configureDescriptionByLinkETDSuspension {
    self.descriptionLabel.text = AMLocalizedString(@"This folder/file was reported to contain objectionable content, such as Child Exploitation Material, Violent Extremism, or Bestiality. The link creator’s account has been closed and their full details, including IP address, have been provided to the authorities.", @"Stand-alone error message shown to users who attempt to load/access a link where the link has been taken down due to severe violation of our terms of service.");;
    [self resetLabels];
}

- (void)configureHeaderInvalidFileLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    self.titleLabel.text = AMLocalizedString(@"File link unavailable", @"Error message shown when opening a file link which doesn’t exist");
}

- (void)configureHeaderInvalidFolderLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFolderLink"];
    self.titleLabel.text = AMLocalizedString(@"Folder link unavailable", @"Error message shown when opening a folder link which doesn’t exist");
}

#pragma mark - Public

- (void)configureInvalidFolderLink {
    [self configureHeaderInvalidFolderLink];
    self.descriptionLabel.text = AMLocalizedString(@"folderLinkUnavailableText1", nil);
    self.firstTextLabel.text = [NSString stringWithFormat: @"• %@", AMLocalizedString(@"folderLinkUnavailableText2", nil)];
    self.secondTextLabel.text = [NSString stringWithFormat: @"• %@", AMLocalizedString(@"folderLinkUnavailableText3", nil)];
    self.thirdTextLabel.text = [NSString stringWithFormat: @"• %@", AMLocalizedString(@"folderLinkUnavailableText4", nil)];
}

- (void)configureInvalidFileLink {
    [self configureHeaderInvalidFileLink];
    self.descriptionLabel.text = AMLocalizedString(@"fileLinkUnavailableText1", nil);
    self.firstTextLabel.text = [NSString stringWithFormat: @"• %@", AMLocalizedString(@"fileLinkUnavailableText2", nil)];
    self.secondTextLabel.text = [NSString stringWithFormat: @"• %@", AMLocalizedString(@"fileLinkUnavailableText3", nil)];
    self.thirdTextLabel.text = [NSString stringWithFormat: @"• %@", AMLocalizedString(@"fileLinkUnavailableText4", nil)];
}

- (void)configureInvalidFileLinkByETD {
    [self configureHeaderInvalidFileLink];
    [self configureDescriptionByLinkETDSuspension];
}

- (void)configureInvalidFolderLinkByETD {
    [self configureHeaderInvalidFolderLink];
    [self configureDescriptionByLinkETDSuspension];
}

- (void)configureInvalidFileLinkByUserETDSuspension {
    [self configureHeaderInvalidFileLink];
    [self configureDescriptionByUserETDSuspension];
}

- (void)configureInvalidFolderLinkByUserETDSuspension {
    [self configureHeaderInvalidFolderLink];
    [self configureDescriptionByUserETDSuspension];
}

- (void)configureInvalidQueryLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    self.titleLabel.text = AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid");
    self.descriptionLabel.text = @"";
    [self resetLabels];
}

@end
