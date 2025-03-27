import AVFoundation
@testable import MEGA
import XCTest

final class AudioPlayerEventObserversLoadingLogicControllerTests: XCTestCase {
    private func makeSUT() -> AudioPlayerEventObserversLoadingLogicController {
        AudioPlayerEventObserversLoadingLogicController()
    }
    
    // MARK: - shouldNotifyLoadingViewWhenReasonForWaitingToPlay Tests (waitingReason is non-nil)
    
    func testWaitingReason_whenWithPositiveCases_shouldReturnTrue() {
        let positiveReasons: [AVPlayer.WaitingReason] = [
            .evaluatingBufferingRate,
            .toMinimizeStalls,
            .interstitialEvent,
            .waitingForCoordinatedPlayback
        ]
        
        positiveReasons.forEach { reason in
            let sut = makeSUT()
            
            let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
                reasonForWaitingToPlay: reason,
                playerStatus: .failed,
                playerTimeControlStatus: .paused,
                isUserPreviouslyJustPlayedSameItem: false
            )
            XCTAssertTrue(result, "Expected true for waiting reason: \(reason)")
        }
    }
    
    func testWaitingReason_whenWithNegativeCase_shouldReturnFalse() {
        let negativeReason: AVPlayer.WaitingReason = .noItemToPlay
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: negativeReason,
            playerStatus: .failed,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertFalse(result, "Expected false for waiting reason: \(negativeReason)")
    }
    
    // MARK: - shouldNotifyLoadingViewWhenReasonForWaitingToPlay Tests (fallback logic when waitingReason is nil)
    
    func testFallback_whenPlayerStatusIsReadyToPlay_shouldReturnFalse() {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertFalse(result, "Expected false when playerStatus is readyToPlay")
    }
    
    func testFallback_whenTimeControlIsPlaying_shouldReturnFalse() {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .failed,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertFalse(result, "Expected false when playerTimeControlStatus is playing")
    }
    
    func testFallback_whenStatusUnknownAndPaused_shouldReturnTrue() {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .unknown,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertTrue(result, "Expected true when playerStatus is unknown and playerTimeControlStatus is paused")
    }
    
    func testFallback_whenStatusFailedAndPaused_shouldReturnTrue() {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .failed,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertTrue(result, "Expected true when playerStatus is failed and playerTimeControlStatus is paused")
    }
    
    func testFallback_whenStatusFailedAndWaitingToPlayAtSpecifiedRate_shouldReturnTrue() {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .failed,
            playerTimeControlStatus: .waitingToPlayAtSpecifiedRate,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertTrue(result, "Expected true when playerStatus is failed and playerTimeControlStatus is waitingToPlayAtSpecifiedRate")
    }
    
    func testFallback_whenStatusUnknownAndWaitingToPlayAtSpecifiedRate_shouldReturnTrue() {
        let sut = makeSUT()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .unknown,
            playerTimeControlStatus: .waitingToPlayAtSpecifiedRate,
            isUserPreviouslyJustPlayedSameItem: false
        )
        XCTAssertTrue(result, "Expected true when playerStatus is unknown and playerTimeControlStatus is waitingToPlayAtSpecifiedRate")
    }
    
    // MARK: - shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus Tests
    
    func testDidChangeCurrentItemStatus_whenUnknown_shouldReturnTrue() {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .unknown)
        XCTAssertEqual(result, true, "Expected true for playerItemStatus .unknown")
    }
    
    func testDidChangeCurrentItemStatus_whenReadyToPlay_shouldReturnTrue() {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .readyToPlay)
        XCTAssertEqual(result, true, "Expected true for playerItemStatus .readyToPlay")
    }
    
    func testDidChangeCurrentItemStatus_whenFailed_shouldReturnFalse() {
        let sut = makeSUT()
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .failed)
        XCTAssertEqual(result, false, "Expected false for playerItemStatus .failed")
    }
}
