import MEGADomain
import MEGADomainMock
import XCTest

class NodesRemovedUseCaseTests: XCTestCase {
    func testRemoveCachedFiles_shouldRemoveFiles() async {
        let thumbnailRepository = MockThumbnailRepository(cachedThumbnailURLs: [
            (.thumbnail, URL(string: "thumbnail/handle1")!),
            (.preview, URL(string: "preview/handle1")!),
            (.original, URL(string: "original/handle1")!)
        ])
        let fileRepository = MockFileSystemRepository()
        let removedNodes = [
            NodeEntity(name: "node1", base64Handle: "handle1")
        ]
        let sut = NodesRemovedUseCase(
            thumbnailRepository: thumbnailRepository,
            fileRepository: fileRepository,
            removedNodes: removedNodes
        )
        
        await sut.removeCachedFiles()
        
        XCTAssertEqual(fileRepository.removeFileURLs, [
            thumbnailRepository.cachedThumbnail(for: removedNodes[0], type: .thumbnail),
            thumbnailRepository.cachedThumbnail(for: removedNodes[0], type: .preview),
            thumbnailRepository.cachedThumbnail(for: removedNodes[0], type: .original)
        ])
    }
}
