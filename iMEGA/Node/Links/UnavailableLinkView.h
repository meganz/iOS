#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UnavailableLinkError) {
    UnavailableLinkErrorGeneric = 0,
    UnavailableLinkErrorETDDown,
    UnavailableLinkErrorUserETDSuspension,
    UnavailableLinkErrorUserCopyrightSuspension,
    UnavailableLinkErrorExpired,
};

@interface UnavailableLinkView : UIView

@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthTextLabel;

- (void)configureInvalidFolderLink;
- (void)configureInvalidFileLink;
- (void)configureInvalidQueryLink;
- (void)configureInvalidFileLinkByETD;
- (void)configureInvalidFolderLinkByETD;
- (void)configureInvalidFileLinkByUserETDSuspension;
- (void)configureInvalidFolderLinkByUserETDSuspension;
- (void)configureInvalidFileLinkByUserCopyrightSuspension;
- (void)configureInvalidFolderLinkByUserCopyrightSuspension;

@end
