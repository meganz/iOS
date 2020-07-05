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

#pragma mark - Public

- (void)configureInvalidFolderLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFolderLink"];
    self.titleLabel.text = AMLocalizedString(@"Folder link unavailable", @"Error message shown when opening a folder link which doesn’t exist");
    self.descriptionLabel.text = AMLocalizedString(@"folderLinkUnavailableText1", nil);
    self.firstTextLabel.text = AMLocalizedString(@"folderLinkUnavailableText2", nil);
    self.secondTextLabel.text = AMLocalizedString(@"folderLinkUnavailableText3", nil);
    self.thirdTextLabel.text = AMLocalizedString(@"folderLinkUnavailableText4", nil);
}

- (void)configureInvalidFileLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    self.titleLabel.text = AMLocalizedString(@"File link unavailable", @"Error message shown when opening a file link which doesn’t exist");
    self.descriptionLabel.text = AMLocalizedString(@"fileLinkUnavailableText1", nil);
    self.firstTextLabel.text = AMLocalizedString(@"fileLinkUnavailableText2", nil);
    self.secondTextLabel.text = AMLocalizedString(@"fileLinkUnavailableText3", nil);
    self.thirdTextLabel.text = AMLocalizedString(@"fileLinkUnavailableText4", nil);
}

- (void)configureInvalidQueryLink {
    self.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    self.titleLabel.text = AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid");
    self.descriptionLabel.text = @"";
    self.firstTextLabel.text = @"";
    self.secondTextLabel.text = @"";
    self.thirdTextLabel.text = @"";
}

@end
