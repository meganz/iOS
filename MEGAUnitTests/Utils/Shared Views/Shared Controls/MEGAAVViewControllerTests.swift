@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGATest
import XCTest

final class MEGAAVViewControllerTests: XCTestCase {
    
    @MainActor
    func testViewDidDissapear_whenDismissingView_shouldCancelPlayerProcessForSmoothStopPlayerExperience() async throws {
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let mockPlayer = MockAVPlayer(url: videoURL)
        let sut = try makeSUT(videoURL: videoURL, player: mockPlayer)
        
        sut.viewDidDisappear(anyBool())
        
        XCTAssertEqual(mockPlayer.pauseCallCount, 1)
        XCTAssertEqual(mockPlayer.currentItemCancelPendingSeeksCallCount, 1)
        XCTAssertEqual(mockPlayer.currentItemAssetCancelLoading, 1)
    }
    
    @MainActor
    func testViewDidDissapear_whenDismissingView_shouldResetsPlayer() async throws {
        let sut = try makeSUT()
        
        sut.viewDidDisappear(anyBool())
        
        XCTAssertNil(sut.player, "Expect player nil, got non nil instead: player instance: \(String(describing: sut.player))")
    }
    
    // MARK: - Loading Indicator
    
    func testWillStartPlayer_whenInvoked_startsLoading() throws {
        let sut = try makeSUT()
        
        sut.startLoading()
        
        XCTAssertTrue(sut.activityIndicator.isAnimating, "Expect true, got false instead.")
    }
    
    func testPlayerDidStall_whenInvoked_stopsLoading() throws {
        let sut = try makeSUT()
        
        sut.playerDidStall()
        
        XCTAssertTrue(sut.activityIndicator.isAnimating, "Expect true, got false instead.")
    }
    
    func testDidChangePlayerItemStatus_whenAttemptStopLoading_stopsLoading() throws {
        let sut = try makeSUT()
        
        let samples: [AVPlayerItem.Status] = [.unknown, .readyToPlay, .failed]
        samples.enumerated().forEach { (index, status) in
            sut.didChangePlayerItemStatus(status)
            
            XCTAssertEqual(sut.activityIndicator.isAnimating, false, "Expect to false, failed instead at index: \(index) with status: \(status)")
        }
    }
    
    func testPlayerDidChangeTimeControlStatus_waitingRate_startsLoading() throws {
        let sut = try makeSUT()
        
        sut.playerDidChangeTimeControlStatus(.waitingToPlayAtSpecifiedRate)
        
        XCTAssertTrue(sut.activityIndicator.isAnimating, "Expect true, got false instead.")
    }
    
    func testPlayerDidChangeTimeControlStatus_whenAttemptStopLoading_startsLoading() throws {
        let sut = try makeSUT()
        
        let samples: [AVPlayer.TimeControlStatus] = [.paused, .playing]
        samples.enumerated().forEach { (index, status) in
            sut.playerDidChangeTimeControlStatus(status)
            
            XCTAssertEqual(sut.activityIndicator.isAnimating, false, "Expect to false, failed instead at index: \(index) with status: \(status)")
        }
    }
    
    // MARK: - Analytics
    
    func testPlayerDidChangeTimeControlStatusHasPlayedOnceBefore_whenStatusPlaying_setHasPlayedOnceBeforeTrue() throws {
        let sut = try makeSUT()
        
        XCTAssertFalse(sut.hasPlayedOnceBefore)
        
        sut.playerDidChangeTimeControlStatus(.playing)
        
        XCTAssertTrue(sut.hasPlayedOnceBefore)
    }
    
    func testHasPlayedOnceBefore_onViewDidLoad_doesNotSetHasPlayedOnceBeforeToTrue() throws {
        let sut = try makeSUT()
        
        XCTAssertFalse(sut.hasPlayedOnceBefore)
    }
    
    func testTrackAnalyticsOnStatus_nonPlaying_DoesNotSetHasPlayedOnceBeforeToTrue() throws {
        let allCases: [AVPlayer.TimeControlStatus] = [.waitingToPlayAtSpecifiedRate, .playing, .paused]
        
        try? allCases
            .filter { $0 != .playing }
            .enumerated()
            .forEach { (index, status) in
                let sut = try makeSUT()
                
                sut.playerDidChangeTimeControlStatus(status)
                
                XCTAssertFalse(sut.hasPlayedOnceBefore, "fail at index: \(index) on status: \(status)")
            }
    }
    
    func testTrackAnalyticsOnStatus_playing_tracksAnalyticsEvent() throws {
        let tracker = MockTracker()
        let sut = try makeSUT()
        
        sut.trackAnalytics(for: .playing, tracker: tracker)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [VideoPlayerIsActivatedEvent()]
        )
    }
    
    func testTrackAnalyticsOnStatus_playingWhenVideoHasPlayedOnceBefore_DoesNotTrackskAnalyticsEvent() throws {
        let tracker = MockTracker()
        let sut = try makeSUT()
        sut.hasPlayedOnceBefore = true
        
        sut.trackAnalytics(for: .playing, tracker: tracker)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testTrackAnalyticsOnStatus_OtherThanPlaying_shouldNotTracksAnalyticsEvent() throws {
        let allCases: [AVPlayer.TimeControlStatus] = [.waitingToPlayAtSpecifiedRate, .playing, .paused]
        
        try? allCases
            .filter { $0 != .playing }
            .forEach { status in
                let tracker = MockTracker()
                let sut = try makeSUT()
                
                sut.trackAnalytics(for: status, tracker: tracker)
                
                assertTrackAnalyticsEventCalled(
                    trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                    with: []
                )
            }
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
