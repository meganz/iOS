
#import <UIKit/UIKit.h>

#import "JSQMessagesCellTextView.h"

@interface MEGAMessageRichPreviewView : UIView

@property (weak, nonatomic) IBOutlet JSQMessagesCellTextView *contentTextView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end
