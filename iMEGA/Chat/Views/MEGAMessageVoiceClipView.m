
#import "MEGAMessageVoiceClipView.h"

@implementation MEGAMessageVoiceClipView

- (IBAction)didTapPlayPauseButton:(UIButton *)sender {
    [self.delegate voiceClipViewShouldPlayOrPause:self];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    [self.delegate voiceClipView:self shouldSeekTo:self.playerSlider.value];
}

@end
