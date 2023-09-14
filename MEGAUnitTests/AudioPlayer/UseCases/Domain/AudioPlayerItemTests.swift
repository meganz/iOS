@testable import MEGA
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerItemTests: XCTestCase {
    
    func testPreferredName_whenCalled_mustUseNodeNameInsteadOfItemName() {
        let originalTrackName = "original-track-name"
        let nodeName = "node-name"
        let node = MockNode(handle: 1, name: nodeName)
        let sut = makeSUT(name: originalTrackName, node: node)
        
        let result = sut.preferredName
        
        XCTAssertEqual(result, nodeName)
    }
    
    func testPreferredName_whenCalled_mustUseTrackNameWhenNodeIsNil() {
        let originalTrackName = originalTrackName()
        let sut = makeSUT(name: originalTrackName)
        
        let result = sut.preferredName
        
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
