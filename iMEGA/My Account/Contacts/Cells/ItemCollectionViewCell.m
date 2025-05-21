#import "ItemCollectionViewCell.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#elif MNZ_WIDGET_EXTENSION
#import "MEGAWidgetExtension-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation ItemCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImages];
}

- (void)configureImages {
    self.thumbnailPlayImageView.image = [UIImage megaImageWithNamed:@"video_list"];
    [self.removeUserButton setImage:[UIImage megaImageWithNamed:@"remove_media"] forState:UIControlStateNormal];
    self.contactVerifiedImageView.image = [UIImage megaImageWithNamed:@"contactVerified"];
}

@end
