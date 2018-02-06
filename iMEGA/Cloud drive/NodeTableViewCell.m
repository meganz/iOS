#import "NodeTableViewCell.h"
#import "MEGASdkManager.h"
#import "Helper.h"

static NSInteger const kCustomEditControlWidth=50;

@interface NodeTableViewCell ()

@property (nonatomic, getter=isPseudoEditing) BOOL pseudoEdit;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *customEditControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSpaceMainViewConstraint;

@end

@implementation NodeTableViewCell

#pragma mark - Life Cycle

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if ([self.customEditDelegate isPseudoEditing]) {
        self.pseudoEdit = editing;
        [self setSwipeOffset:0];
        [self beginEditMode];
    } else {
        [super setEditing:editing animated:animated];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.customEditControl.selected = selected;
}

#pragma mark - Private Method

// Animate view to show/hide custom edit control/button
- (void)beginEditMode {
    if (!self.isSwiping) {
        self.leadingSpaceMainViewConstraint.constant = self.isPseudoEditing ? 0 : -kCustomEditControlWidth;
    } else {
        self.isSwiping = NO;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.mainView.superview layoutIfNeeded];
    }];
}

- (IBAction)cancelTransfer:(id)sender {
    NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:[MEGASdk base64HandleForHandle:self.nodeHandle]];
    if ([[MEGASdkManager sharedMEGASdk] transferByTag:transferTag.integerValue] != nil) {
        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
    } else {
        if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:transferTag.integerValue] != nil) {
            [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transferTag.integerValue];
        }
    }
}

@end
