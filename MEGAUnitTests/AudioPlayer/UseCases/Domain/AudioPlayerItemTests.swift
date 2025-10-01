@testable import MEGA
import MEGAAppSDKRepoMock
import Testing

@Suite("AudioPlayerItem")
struct AudioPlayerItemTests {
    private let originalName = "original-track-name"
    private let nodeName = "node-name"
    private let url = URL(string: "https://any-url.com")!
    private let node = MockNode(handle: 1, name: "node-name")
    
    private func makeSUT(name: String, node: MockNode? = nil) -> AudioPlayerItem {
        AudioPlayerItem(
            name: name,
            url: url,
            node: node
        )
    }
    
    @Test("name uses node.name when node exists")
    func nameUsesNodeName() {
        let sut = makeSUT(name: originalName, node: node)
        #expect(sut.name == nodeName)
    }
    
    @Test("name falls back to track name when node is nil")
    func nameFallsBackToTrackNameWhenNodeIsNil() {
        let sut = makeSUT(name: originalName)
        #expect(sut.name == originalName)
    }
}
