
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGAMessageVoiceClipView;

@protocol MEGAMessageVoiceClipViewDelegate <NSObject>
- (void)voiceClipViewShouldPlayOrPause:(MEGAMessageVoiceClipView *)voiceClipView;
- (void)voiceClipView:(MEGAMessageVoiceClipView *)voiceClipView shouldSeekTo:(float)destination;
@end

@interface MEGAMessageVoiceClipView : UIView

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UISlider *playerSlider;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

// A delegate usually should be weak to avoid a retain cycle, but in this case the delegate
// would be freed if it is marked as weak. That is the reason why it is not weak.
@property (nonatomic) id<MEGAMessageVoiceClipViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
