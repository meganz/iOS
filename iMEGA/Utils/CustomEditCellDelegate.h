
static NSInteger const kCustomEditControlWidth=50;

@protocol CustomEditCellDelegate

@property (nonatomic, readonly, getter=isPseudoEditing) BOOL pseudoEdit;

@end

@protocol CustomEditCellAnimations

// Animate view to show/hide custom edit control/button
- (void)beginEditMode;
- (void)endEditMode;

@end
