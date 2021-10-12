#import "UnavailableLinkView.h"

#import "MEGA-Swift.h"

@implementation UnavailableLinkView

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
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

- (NSAttributedString *)linkAttributedString:(NSString *)text {
    NSRange r1 = [text rangeOfString:@"[A]"];
    NSRange r2 = [text rangeOfString:@"[/A]"];
    NSRange range = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
    NSString *termsString = [text substringWithRange:range];
    text = text.mnz_removeWebclientFormatters;
    NSMutableAttributedString *attributedText = [NSMutableAttributedString.alloc initWithString:text];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor mnz_redForTraitCollection:self.traitCollection] range:[text rangeOfString:termsString]];
    return attributedText;
}

- (void)configureDescriptionByUserETDSuspension {
    [self.descriptionLabel addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showTerms)]];
    self.descriptionLabel.userInteractionEnabled = YES;
    self.descriptionLabel.attributedText = [self linkAttributedString:NSLocalizedString(@"This link is unavailable as the user’s account has been closed for gross violation of MEGA’s [A]Terms of Service[/A].", @"Stand-alone error message shown to users who attempt to load/access a link where the user has been suspended/taken-down due to severe violation of our terms of service.")];
    [self resetLabels];
}

- (void)configureDescriptionByUserCopyrightSuspension {
    [self.descriptionLabel addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showTerms)]];
    self.descriptionLabel.userInteractionEnabled = YES;
    self.descriptionLabel.attributedText = [self linkAttributedString:NSLocalizedString(@"The account that created this link has been terminated due to multiple violations of our [A]Terms of Service[/A].", @"An error message which is shown when you open a file/folder link (or other shared resource) and it’s no longer available because the user account that created the link has been terminated due to multiple violations of our Terms of Service.")];
    [self resetLabels];
}

- (void)configureDescriptionByLinkETDSuspension {
    self.descriptionLabel.text = NSLocalizedString(@"Taken down due to severe violation of our terms of service", @"Stand-alone error message shown to users who attempt to load/access a link where the link has been taken down due to severe violation of our terms of service.");;
    [self resetLabels];
}

- (void)configureHeaderInvalidFileLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    self.titleLabel.text = NSLocalizedString(@"File link unavailable", @"Error message shown when opening a file link which doesn’t exist");
}

- (void)configureHeaderInvalidFolderLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFolderLink"];
    self.titleLabel.text = NSLocalizedString(@"Folder link unavailable", @"Error message shown when opening a folder link which doesn’t exist");
}

#pragma mark - Public

- (void)configureInvalidFolderLink {
    [self configureHeaderInvalidFolderLink];
    self.descriptionLabel.text = NSLocalizedString(@"folderLinkUnavailableText1", nil);
    self.firstTextLabel.text = [NSString stringWithFormat: @"• %@", NSLocalizedString(@"folderLinkUnavailableText2", nil)];
    self.secondTextLabel.text = [NSString stringWithFormat: @"• %@", NSLocalizedString(@"folderLinkUnavailableText3", nil)];
    self.thirdTextLabel.text = [NSString stringWithFormat: @"• %@", NSLocalizedString(@"folderLinkUnavailableText4", nil)];
}

- (void)configureInvalidFileLink {
    [self configureHeaderInvalidFileLink];
    self.descriptionLabel.text = NSLocalizedString(@"fileLinkUnavailableText1", nil);
    self.firstTextLabel.text = [NSString stringWithFormat: @"• %@", NSLocalizedString(@"fileLinkUnavailableText2", nil)];
    self.secondTextLabel.text = [NSString stringWithFormat: @"• %@", NSLocalizedString(@"fileLinkUnavailableText3", nil)];
    self.thirdTextLabel.text = [NSString stringWithFormat: @"• %@", NSLocalizedString(@"fileLinkUnavailableText4", nil)];
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

- (void)configureInvalidFileLinkByUserCopyrightSuspension {
    [self configureHeaderInvalidFileLink];
    [self configureDescriptionByUserCopyrightSuspension];
}

- (void)configureInvalidFolderLinkByUserCopyrightSuspension {
    [self configureHeaderInvalidFolderLink];
    [self configureDescriptionByUserCopyrightSuspension];
}

- (void)configureInvalidQueryLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    self.titleLabel.text = NSLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid");
    self.descriptionLabel.text = @"";
    [self resetLabels];
}

@end
