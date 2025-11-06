import Testing
@testable import MEGAVideoPlayer
import AVFoundation

struct VideoScalingModeTests {
    @Test(arguments: [
        (VideoScalingMode.fit, AVLayerVideoGravity.resizeAspect),
        (.fill, .resizeAspectFill)
    ])
    func toAVLayerVideoGravity(
        scalingMode: VideoScalingMode,
        expectedVideoGravity: AVLayerVideoGravity
    ) {
        let videoGravity = scalingMode.toAVLayerVideoGravity()

        #expect(videoGravity == expectedVideoGravity)
    }
    
    @Test(arguments: [
        (VideoScalingMode.fit, VideoScalingMode.fill),
        (.fill, .fit)
    ])
    func toggled(
        scalingMode: VideoScalingMode,
        expectedToggledScalingMode: VideoScalingMode
    ) {
        let result = scalingMode.toggled()

        #expect(result == expectedToggledScalingMode)
    }
} 
