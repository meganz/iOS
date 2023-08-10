@testable import MEGA
import MEGATest
import XCTest

final class MEGAAVViewControllerLoadingDecoratorTests: XCTestCase {
    
    func testViewDidLoad_whenInvoked_assignDelegate() throws {
        let sut = try makeSUT(videoViewController: makeVideoViewController())
        
        XCTAssertTrue(sut.decoratee.avViewControllerDelegate is MEGAAVViewControllerLoadingDecorator)
    }

    func testWillStartPlayer_whenInvoked_startsLoading() throws {
        let sut = try makeSUT()
        
        sut.willStartPlayer()
        
        XCTAssertTrue(sut.activityIndicator.isAnimating, "Expect true, got false instead.")
    }
    
    func testDidStartPlayer_whenInvoked_stopsLoading() throws {
        let sut = try makeSUT()
        
        sut.didStartPlayer()
        
        XCTAssertFalse(sut.activityIndicator.isAnimating, "Expect false, got true instead.")
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
    
    // MARK: - Helpers
    
    private func makeSUT(videoViewController: MEGAAVViewController, file: StaticString = #filePath, line: UInt = #line) throws -> MEGAAVViewControllerLoadingDecorator {
        let sut = MEGAAVViewControllerLoadingDecorator(decoratee: videoViewController)
        sut.viewDidLoad()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> MEGAAVViewControllerLoadingDecorator {
        let videoViewController = try makeVideoViewController()
        let sut = MEGAAVViewControllerLoadingDecorator(decoratee: videoViewController)
        sut.viewDidLoad()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeVideoViewController(file: StaticString = #filePath, line: UInt = #line) throws -> MEGAAVViewController {
        let videoURL = URL(string: "file://videos/abc.mp4")!
        let videoViewController = try XCTUnwrap(MEGAAVViewController(url: videoURL), file: file, line: line)
        videoViewController.player = AVPlayer(url: videoURL)
        return videoViewController
    }

}
