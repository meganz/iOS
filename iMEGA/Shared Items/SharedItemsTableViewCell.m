#import "SharedItemsTableViewCell.h"

static NSInteger const kCustomEditControlWidth=50;

@interface SharedItemsTableViewCell ()

@property (nonatomic, getter=isPseudoEditing) BOOL pseudoEdit;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *customEditControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSpaceMainViewConstraint;

@end

@implementation SharedItemsTableViewCell

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

@end
