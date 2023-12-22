import AVFoundation
@testable import MEGA
import XCTest

final class AudioPlayerEventObserversLoadingLogicControllerTests: XCTestCase {
    
    // MARK: - shouldNotifyLoadingViewWhenReasonForWaitingToPlay
    
    func testWaitingReason_EvaluatingBufferingRate_ReturnsTrue() {
        let allReasons: [AVPlayer.WaitingReason] = [ .evaluatingBufferingRate, .toMinimizeStalls, .interstitialEvent, .waitingForCoordinatedPlayback ]
        allReasons.enumerated().forEach { (index, reasonForWaitingToPlay) in
            let sut = AudioPlayerEventObserversLoadingLogicController()
            
            let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
                reasonForWaitingToPlay: reasonForWaitingToPlay,
                playerStatus: anyPlayerStatus(),
                playerTimeControlStatus: playerTimeControlStatus(),
                isUserPreviouslyJustPlayedSameItem: anyBool()
            )
            
            XCTAssertTrue(result, "Expect to got true, but fail instead at index: \(index), for reasonForWaitingToPlay: \(reasonForWaitingToPlay)")
        }
    }
    
    func testWaitingReason_DefaultCase_ReturnsFalse() {
        let allReasons: [AVPlayer.WaitingReason?] = [ .noItemToPlay ]
        allReasons.enumerated().forEach { (index, reasonForWaitingToPlay) in
            let sut = AudioPlayerEventObserversLoadingLogicController()
            
            let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
                reasonForWaitingToPlay: reasonForWaitingToPlay,
                playerStatus: anyPlayerStatus(),
                playerTimeControlStatus: playerTimeControlStatus(),
                isUserPreviouslyJustPlayedSameItem: anyBool()
            )
            
            XCTAssertFalse(result, "Expect to got false, but fail instead at index: \(index), for reasonForWaitingToPlay: \(String(describing: reasonForWaitingToPlay))")
        }
    }
    
    func testNilWaitingReason_PlayerStatusUnknown_TimeControlPaused_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .unknown,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: true
        )
        
        XCTAssertTrue(result)
    }
    
    func testNilWaitingReason_ReadyToPlay_Paused_IsUserPreviouslyJustPlayedSameItem_ReturnsFalse() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: true
        )
        
        XCTAssertFalse(result)
    }
    
    func testNilWaitingReason_ReadyToPlay_NotPaused_IsUserPreviouslyJustPlayedSameItem_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: true
        )
        
        XCTAssertTrue(result)
    }
    
    func testNilWaitingReason_ReadyToPlay_NotPaused_IsUserPreviouslyNotPlayedSameItem_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: false
        )
        
        XCTAssertTrue(result)
    }
    
    func testNilWaitingReason_Unknown_NotPaused_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .unknown,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: false
        )
        
        XCTAssertTrue(result)
    }
    
    func testPlayerReadyToPlay_Paused_IsUserPreviouslyJustPlayedSameItem_ReturnsFalse() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: true
        )
        
        XCTAssertFalse(result)
    }
    
    // MARK: - shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus
    
    func testShouldNotifyLoadingViewWhenDidChangeCurrentItemStatus_UnknownStatus_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .unknown)
        
        XCTAssertEqual(result, true)
    }
    
    func testShouldNotifyLoadingViewWhenDidChangeCurrentItemStatus_ReadyToPlayStatus_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .readyToPlay)
        
        XCTAssertEqual(result, true)
    }
    
    func testShouldNotifyLoadingViewWhenDidChangeCurrentItemStatus_FailedStatus_ReturnsFalse() {
        let sut = AudioPlayerEventObserversLoadingLogicController()
        
        let result = sut.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: .failed)
        
        XCTAssertEqual(result, false)
    }
    
    // MARK: - Helpers
    
    private func anyPlayerStatus() -> AVPlayer.Status {
        let items: [ AVPlayer.Status ] = [ .failed, .readyToPlay, .unknown ]
        return items.randomElement() ?? .failed
    }
    
    private func playerTimeControlStatus() -> AVPlayer.TimeControlStatus {
        let items: [ AVPlayer.TimeControlStatus ] = [ .paused, .playing, .waitingToPlayAtSpecifiedRate ]
        return items.randomElement() ?? .paused
    }
    
    private func anyBool() -> Bool {
        .random()
    }
}
