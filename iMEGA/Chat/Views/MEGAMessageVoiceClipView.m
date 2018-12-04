
#import "MEGAMessageVoiceClipView.h"

@implementation MEGAMessageVoiceClipView

- (IBAction)didTapPlayPauseButton:(UIButton *)sender {
    self.playing = !self.isPlaying;
    if (self.isPlaying) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"pauseVoiceClip"] forState:UIControlStateNormal];
    } else {
        [self.playPauseButton setImage:[UIImage imageNamed:@"playVoiceClip"] forState:UIControlStateNormal];
    }
    [self.delegate voiceClipView:self shouldPlay:self.playing];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    [self.delegate voiceClipView:self shouldSeekTo:self.playerSlider.value];
}

@end
