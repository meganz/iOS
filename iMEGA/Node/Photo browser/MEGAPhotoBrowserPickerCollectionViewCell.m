#import "MEGAPhotoBrowserPickerCollectionViewCell.h"
#import "MEGA-Swift.h"

@implementation MEGAPhotoBrowserPickerCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.playView.image = [UIImage megaImageWithNamed:@"video_list"];
}

@end
