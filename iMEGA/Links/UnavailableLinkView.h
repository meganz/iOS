#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UnavailableLinkError) {
    UnavailableLinkErrorGeneric = 0,
    UnavailableLinkErrorETDDown,
    UnavailableLinkErrorUserETDSuspension,
    UnavailableLinkErrorUserCopyrightSuspension,
};

@interface UnavailableLinkView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdTextLabel;

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
