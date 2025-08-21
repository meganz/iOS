@testable import MEGAVideoPlayer
import Testing

struct VideoOrientationTests {
    
    @Test(arguments: [
        (VideoOrientation.portrait, VideoOrientation.landscape),
        (.landscape, .portrait)
    ])
    func toggled_returnsCorrectOrientation(
        initialOrientation: VideoOrientation,
        expectedToggledOrientation: VideoOrientation
    ) {
        let result = initialOrientation.toggled()
        
        #expect(result == expectedToggledOrientation)
    }
    
    @Test(arguments: VideoOrientation.allCases)
    func toggled_isReversible(orientation: VideoOrientation) {
        let result = orientation.toggled().toggled()
        
        #expect(result == orientation)
    }
}