import AVFoundation
@testable import MEGA
import XCTest

final class ReasonWaitingToPlayNilLogicControllerTests: XCTestCase {
    private func makeSUT() -> AudioPlayerEventObserversLoadingLogicController {
        AudioPlayerEventObserversLoadingLogicController()
    }
    
    private func assertWaitingReasonNotification(
        waitingReason: AVPlayer.WaitingReason,
        expected: Bool
    ) {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: waitingReason,
            playerStatus: .failed,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertEqual(result, expected, "For waitingReason \(waitingReason), expected \(expected) but got \(result)")
    }
    
    private func assertFallbackNotification(
        playerStatus: AVPlayer.Status,
        timeControlStatus: AVPlayer.TimeControlStatus,
        expected: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: playerStatus,
            playerTimeControlStatus: timeControlStatus,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertEqual(result, expected, "For (\(playerStatus), \(timeControlStatus)) expected \(expected) but got \(result)")
    }
    
    func testWaitingReason_whenWaitingReasonIsPositive_shouldReturnTrue() {
        let positiveReasons: [AVPlayer.WaitingReason] = [
            .evaluatingBufferingRate,
            .toMinimizeStalls,
            .interstitialEvent,
            .waitingForCoordinatedPlayback
        ]
        positiveReasons.forEach { reason in
            assertWaitingReasonNotification(waitingReason: reason, expected: true)
        }
    }
    
    func testWaitingReason_whenWaitingReasonIsNoItemToPlay_shouldReturnFalse() {
        let negativeReason: AVPlayer.WaitingReason = .noItemToPlay
        assertWaitingReasonNotification(waitingReason: negativeReason, expected: false)
    }
    
    func testFallback_whenPlayerStatusIsReadyToPlayAndReasonIsNil_shouldReturnFalse() {
        assertFallbackNotification(playerStatus: .readyToPlay, timeControlStatus: .paused, expected: false)
        assertFallbackNotification(playerStatus: .readyToPlay, timeControlStatus: .waitingToPlayAtSpecifiedRate, expected: false)
    }
    
    func testFallback_whenTimeControlStatusIsPlayingAndReasonIsNil_shouldReturnFalse() {
        assertFallbackNotification(playerStatus: .failed, timeControlStatus: .playing, expected: false)
        assertFallbackNotification(playerStatus: .unknown, timeControlStatus: .playing, expected: false)
    }
    
    func testFallback_whenPlayerStatusIsUnknownAndPausedAndReasonIsNil_shouldReturnTrue() {
        assertFallbackNotification(playerStatus: .unknown, timeControlStatus: .paused, expected: true)
    }
    
    func testFallback_whenDefaultCasesAndReasonIsNil_shouldReturnTrue() {
        assertFallbackNotification(playerStatus: .failed, timeControlStatus: .paused, expected: true)
        assertFallbackNotification(playerStatus: .failed, timeControlStatus: .waitingToPlayAtSpecifiedRate, expected: true)
        assertFallbackNotification(playerStatus: .unknown, timeControlStatus: .waitingToPlayAtSpecifiedRate, expected: true)
    }
    
    func testDidChangeCurrentItemStatus_whenPlayerItemStatusIsUnknown_shouldReturnTrue() {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .unknown)
        XCTAssertEqual(result, true)
    }
    
    func testDidChangeCurrentItemStatus_whenPlayerItemStatusIsReadyToPlay_shouldReturnTrue() {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .readyToPlay)
        XCTAssertEqual(result, true)
    }
    
    func testDidChangeCurrentItemStatus_whenPlayerItemStatusIsFailed_shouldReturnFalse() {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .failed)
        XCTAssertEqual(result, false)
    }
}
