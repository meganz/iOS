@testable import MEGA
import MEGASDKRepoMock
import XCTest

final class SetVideoPlayerItemMetadataCommandTests: XCTestCase {

    @MainActor
    func testExecute_whenCalled_shouldSetVideoPlayerNeededMetadataOnly() async {
        let anyURL = URL(string: "www.any-url.com")!
        let mockPlayerItem = AVPlayerItem(url: anyURL)
        let sut = SetVideoPlayerItemMetadataCommand(
            playerItem: mockPlayerItem,
            node: MockNode(handle: 1),
            fileManager: FileManager(),
            sdk: MockSdk(),
            nodeAssetManager: NodeAssetsManager(sdk: MockSdk())
        )
        
        await sut.execute()
        
        XCTAssertTrue(mockPlayerItem.externalMetadata.contains(where: { $0.identifier == .commonIdentifierTitle }))
        XCTAssertTrue(mockPlayerItem.externalMetadata.contains(where: { $0.identifier == .commonIdentifierArtwork }))
        
        XCTAssertTrue(mockPlayerItem.externalMetadata.notContains(where: { $0.identifier == .iTunesMetadataTrackSubTitle }))
        XCTAssertTrue(mockPlayerItem.externalMetadata.notContains(where: { $0.identifier == .commonIdentifierDescription }))
    }

}
