@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing
import UIKit

@MainActor
struct MEGAPlayerViewControllerTests {

    // MARK: - Helper

    private func makeSUT(player: MockVideoPlayer = MockVideoPlayer()) -> MEGAPlayerViewController {
        let sut = MEGAPlayerViewController(
            viewModel: MEGAPlayerViewModel(
                player: player,
                nowPlayingController: VideoNowPlayingController(
                    player: player,
                    infoCenter: MockNowPlayingInfoCenter(),
                    commandCenter: MockNowPlayingRemoteCommandCenter(),
                    artworkProvider: MockVideoNowPlayingArtworkProvider()
                )
            ),
            pictureInPicturePresenter: { nil }
        )
        sut.loadViewIfNeeded()
        return sut
    }

    // MARK: - System overlays

    @Test
    func init_capturesStatusBarAppearance() {
        let sut = makeSUT()

        #expect(sut.modalPresentationCapturesStatusBarAppearance)
    }

    @Test
    func controlsVisible_showsStatusBarAndHomeIndicator() throws {
        let sut = makeSUT()

        #expect(try #require(sut.overlayViewModel).isControlsVisible)
        #expect(!sut.prefersStatusBarHidden)
        #expect(!sut.prefersHomeIndicatorAutoHidden)
    }

    @Test
    func hideControls_hidesStatusBarAndAutoHidesHomeIndicator() throws {
        let sut = makeSUT()

        try #require(sut.overlayViewModel).hideControls()

        #expect(sut.prefersStatusBarHidden)
        #expect(sut.prefersHomeIndicatorAutoHidden)
    }

    @Test
    func showControlsAfterHiding_showsStatusBarAndHomeIndicatorAgain() throws {
        let sut = makeSUT()
        let overlayViewModel = try #require(sut.overlayViewModel)
        overlayViewModel.hideControls()

        overlayViewModel.showControls()

        #expect(!sut.prefersStatusBarHidden)
        #expect(!sut.prefersHomeIndicatorAutoHidden)
    }
}
