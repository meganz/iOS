import AVFoundation
import Foundation
@testable import MEGA
import MEGADataMock
import XCTest

@MainActor
final class MEGAAVViewControllerTests: XCTestCase {

    func testViewDidLoad_whenVideoIsFinishedAtEndTime_shouldReplayVideo() async throws {
        let sut = try makeSUT()
        await sut.simulateVideoPlayerAtEndOfRate()
        
        let exp = expectation(description: "simulate main dispatch")
        sut.simulateNotificationVideoPlayerFinishToPlayAtEndTime()
        exp.fulfill()
        await fulfillment(of: [exp], timeout: 1.0)
        
        assertThatVideoPlayerIsResettedBeforeReplay(sut)
        assertThatVideoPlayerIsPlaying(sut)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() throws -> MEGAAVViewController {
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let sut = try XCTUnwrap(MEGAAVViewController(url: videoURL))
        sut.player = AVPlayer(url: videoURL)
        sut.viewDidLoad()
        return sut
    }
    
    private func assertThatVideoPlayerIsResettedBeforeReplay(_ sut: MEGAAVViewController, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.player?.currentTime().seconds, 0.0, file: file, line: line)
        XCTAssertNil(sut.player?.error, file: file, line: line)
        XCTAssertEqual(sut.player?.status, .readyToPlay, file: file, line: line)
        XCTAssertEqual(sut.player?.timeControlStatus, .waitingToPlayAtSpecifiedRate, file: file, line: line)
    }
    
    private func assertThatVideoPlayerIsPlaying(_ sut: MEGAAVViewController, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.player?.rate, sut.player?.defaultRate)
        XCTAssertEqual(sut.player?.rate, 1.0)
    }
}

private extension MEGAAVViewController {
    func simulateVideoPlayerAtEndOfRate() async {
        await player?.seek(to: .positiveInfinity)
    }
    
    func simulateNotificationVideoPlayerFinishToPlayAtEndTime() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
}
