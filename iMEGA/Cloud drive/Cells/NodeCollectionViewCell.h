
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NodeCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailIconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;

- (void)configureCellForNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
