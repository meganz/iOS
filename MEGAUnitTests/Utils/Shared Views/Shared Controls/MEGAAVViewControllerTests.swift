import XCTest

@MainActor
final class MEGAAVViewControllerTests: XCTestCase {
    
    func testViewDidDissapear_whenDismissingView_shouldCancelPlayerProcessForSmoothStopPlayerExperience() async throws {
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let mockPlayer = MockAVPlayer(url: videoURL)
        let sut = try makeSUT(videoURL: videoURL, player: mockPlayer)
        
        sut.viewDidDisappear(anyBool())
        
        XCTAssertEqual(mockPlayer.pauseCallCount, 1)
        XCTAssertEqual(mockPlayer.currentItemCancelPendingSeeksCallCount, 1)
        XCTAssertEqual(mockPlayer.currentItemAssetCancelLoading, 1)
    }
    
    func testViewDidDissapear_whenDismissingView_shouldResetsPlayer() async throws {
        let sut = try makeSUT()
        
        sut.viewDidDisappear(anyBool())
        
        XCTAssertNil(sut.player, "Expect player nil, got non nil instead: player instance: \(String(describing: sut.player))")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(videoURL: URL? = URL(string: "file://videos/abc.mp4")!) throws -> MEGAAVViewController {
        let videoURL = try XCTUnwrap(videoURL)
        let sut = try XCTUnwrap(MEGAAVViewController(url: videoURL))
        sut.player = AVPlayer(url: videoURL)
        sut.viewDidLoad()
        return sut
    }
    
    private func makeSUT(videoURL: URL, player: AVPlayer) throws -> MEGAAVViewController {
        let videoURL = try XCTUnwrap(videoURL)
        let sut = try XCTUnwrap(MEGAAVViewController(url: videoURL))
        sut.player = player
        sut.viewDidLoad()
        return sut
    }
    
    private func anyBool() -> Bool {
        false
    }
}

private final class MockAVPlayer: AVPlayer {
    private(set) var pauseCallCount = 0
    private(set) var currentItemCancelPendingSeeksCallCount = 0
    private(set) var currentItemAssetCancelLoading = 0
    
    override func pause() {
        pauseCallCount += 1
        currentItemCancelPendingSeeksCallCount += 1
        currentItemAssetCancelLoading += 1
    }
}
