import AVFoundation
@testable import MEGA
import XCTest

class ReasonWaitingToPlayNilLogicControllerTests: XCTestCase {

    func testUnknownStatusPausedTimeControl_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController.ReasonWaitingToPlayNilLogicController()
        
        let result = sut.shouldNotifyLoadingView(
            reasonForWaitingToPlay: nil,
            playerStatus: .unknown,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        
        XCTAssertTrue(result)
    }
    
    func testReadyToPlayPausedSameItem_ReturnsFalse() {
        let sut = AudioPlayerEventObserversLoadingLogicController.ReasonWaitingToPlayNilLogicController()
        
        let result = sut.shouldNotifyLoadingView(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: true
        )
        
        XCTAssertFalse(result)
    }
    
    func testReadyToPlayNotPausedSameItem_ReturnsFalse() {
        let sut = AudioPlayerEventObserversLoadingLogicController.ReasonWaitingToPlayNilLogicController()
        
        let result = sut.shouldNotifyLoadingView(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: true
        )
        
        XCTAssertFalse(result)
    }
    
    func testReadyToPlayNotPausedNotSameItem_ReturnsFalse() {
        let sut = AudioPlayerEventObserversLoadingLogicController.ReasonWaitingToPlayNilLogicController()
        
        let result = sut.shouldNotifyLoadingView(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: false
        )
        
        XCTAssertFalse(result)
    }
    
    func testUnknownNotPaused_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController.ReasonWaitingToPlayNilLogicController()
        
        let result = sut.shouldNotifyLoadingView(
            reasonForWaitingToPlay: nil,
            playerStatus: .unknown,
            playerTimeControlStatus: .playing,
            isUserPreviouslyJustPlayedSameItem: false
        )
        
        XCTAssertTrue(result)
    }
    
    func testReadyToPlayPausedDifferentItem_ReturnsTrue() {
        let sut = AudioPlayerEventObserversLoadingLogicController.ReasonWaitingToPlayNilLogicController()
        
        let result = sut.shouldNotifyLoadingView(
            reasonForWaitingToPlay: nil,
            playerStatus: .readyToPlay,
            playerTimeControlStatus: .paused,
            isUserPreviouslyJustPlayedSameItem: false
        )
        
        XCTAssertTrue(result)
    }
}
