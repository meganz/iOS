@testable import MEGA
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerItemTests: XCTestCase {
    
    func testName_whenCalled_mustUseNodeNameInsteadOfItemName() {
        let originalTrackName = "original-track-name"
        let nodeName = "node-name"
        let node = MockNode(handle: 1, name: nodeName)
        let sut = makeSUT(name: originalTrackName, node: node)
        
        let result = sut.name
        
        XCTAssertEqual(result, nodeName)
    }
    
    func testName_whenCalled_mustUseTrackNameWhenNodeIsNil() {
        let originalTrackName = originalTrackName()
        let sut = makeSUT(name: originalTrackName)
        
        let result = sut.name
        
        XCTAssertEqual(result, originalTrackName)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(name: String, node: MockNode? = nil, file: StaticString = #filePath, line: UInt = #line) -> AudioPlayerItem {
        let anyURL = URL(string: "https://any-url.com")!
        let sut = AudioPlayerItem(name: name, url: anyURL, node: node)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func originalTrackName() -> String {
        "original-track-name"
    }
    
}
