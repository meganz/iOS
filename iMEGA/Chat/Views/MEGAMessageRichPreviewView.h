
#import <UIKit/UIKit.h>

#import "JSQMessagesCellTextView.h"

@interface MEGAMessageRichPreviewView : UIView

@property (weak, nonatomic) IBOutlet JSQMessagesCellTextView *contentTextView;

@property (weak, nonatomic) IBOutlet UIView *richPreviewView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;
@property (weak, nonatomic) IBOutlet UIView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *richViewHeightConstraint;

@end
