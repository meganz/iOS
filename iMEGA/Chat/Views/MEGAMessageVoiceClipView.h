
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

@property (weak, nonatomic) id<MEGAMessageVoiceClipViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
