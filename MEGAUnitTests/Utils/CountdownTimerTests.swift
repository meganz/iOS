import Combine
@testable import MEGA
import XCTest

final class CountdownTimerTests: XCTestCase {

    func testStartCountdown_withSecondsGreaterThanZero_shouldStartCountdown() {
        let sut = CountdownTimer()
        let testSeconds = Int.random(in: 1..<3)
        
        let exp = expectation(description: "Should start countdown and wait till zero to finish")
        sut.startCountdown(seconds: testSeconds) { newDuration in
            if newDuration == 0 {
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 4)
        XCTAssertNil(sut.timerCancellable, "Expected nil, got non nil instead")
    }
    
    func testStartCountdown_withZeroSeconds_shouldNotStartCountdown() {
        let sut = CountdownTimer()
        let testSeconds = 0
        
        let exp = expectation(description: "Should start countdown and wait till zero to finish")
        var remainingDuration = 0
        sut.startCountdown(seconds: testSeconds) { newDuration in
            remainingDuration = newDuration
            if newDuration == 0 {
                exp.fulfill()
            } else {
                XCTFail("Expected new duration to be zero only")
            }
        }
        
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(remainingDuration == 0)
        XCTAssertNil(sut.timerCancellable, "Expected nil, got non nil instead")
    }
    
    func testStartCountdown_withOngoingCountdown_shouldRestartCountdown() {
        let sut = CountdownTimer()
        let testSeconds = 3
        var remainingSeconds = 0
        
        let firstCountDownExp = expectation(description: "Should start first countdown")
        let startNewCountdownSeconds = 2
        sut.startCountdown(seconds: testSeconds) { newDuration in
            remainingSeconds = newDuration
            if newDuration == startNewCountdownSeconds {
                firstCountDownExp.fulfill()
            }
        }
        wait(for: [firstCountDownExp], timeout: 5)
        XCTAssertTrue(remainingSeconds == startNewCountdownSeconds, "Last countdown duration should be \(startNewCountdownSeconds)")
        XCTAssertNotNil(sut.timerCancellable, "Expected not to be nil, got nil instead")
        
        let secondCountdownExp = expectation(description: "Should start new countdown, restart count and wait till zero to finish")
        var durationList = [Int]()
        sut.startCountdown(seconds: testSeconds) { newDuration in
            remainingSeconds = newDuration
            durationList.append(newDuration)
            if newDuration == 0 {
                secondCountdownExp.fulfill()
            }
        }
        wait(for: [secondCountdownExp], timeout: 5)
        let testSecondsList = (0...testSeconds).sorted(by: >)
        XCTAssertEqual(durationList, testSecondsList)
        XCTAssertNil(sut.timerCancellable, "Expected nil, got non nil instead")
    }
    
    func testStopCountdown_withOngoingCountdown_shouldStopCountdown() {
        let sut = CountdownTimer()
        let testSeconds = 3
        let secondsToStop = 1
        
        let exp = expectation(description: "Should stop ongoing countdown")
        var remainingDuration = 0
        sut.startCountdown(seconds: testSeconds) { newDuration in
            remainingDuration = newDuration
            if newDuration == secondsToStop {
                sut.stopCountdown()
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 4)
        XCTAssertTrue(remainingDuration == secondsToStop)
        XCTAssertNil(sut.timerCancellable, "Expected nil, got non nil instead")
    }
    
    func testStopCountdown_withNoOngoingCountdown_shouldHaveNoActiveTimer() {
        let sut = CountdownTimer()
        XCTAssertNil(sut.timerCancellable, "Expected nil initially, got non nil instead")
        
        sut.stopCountdown()
        XCTAssertNil(sut.timerCancellable, "Expected nil, got non nil instead")
    }
}
