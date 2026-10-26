import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeListEntity - visual media checks")
struct NodeListEntityVisualMediaTests {

    /// A folder can carry an image or video extension in its name (IOS-12875).
    @Test("A folder named like an image is not media, so the list is not only media")
    func containsOnlyVisualMedia_withFolderNamedLikeImage_isFalse() {
        let list = makeList([file("IMG1.jpg"), file("IMG2.jpg"), folder("Album.jpg")])

        #expect(!list.containsOnlyVisualMedia())
    }

    @Test("Image and video files alone are only media")
    func containsOnlyVisualMedia_withMediaFilesOnly_isTrue() {
        let list = makeList([file("IMG1.jpg"), file("clip.mp4")])

        #expect(list.containsOnlyVisualMedia())
    }

    @Test("Folders named like media don't count as media")
    func containsVisualMedia_withOnlyFoldersNamedLikeMedia_isFalse() {
        let list = makeList([folder("Trip.jpg"), folder("Clips.mp4"), file("notes.txt")])

        #expect(!list.containsVisualMedia())
    }

    @Test("One media file is enough")
    func containsVisualMedia_withAMediaFile_isTrue() {
        let list = makeList([folder("Trip.jpg"), file("a.jpg")])

        #expect(list.containsVisualMedia())
    }

    @Test("A folder named like an image has no media type")
    func toNodeEntity_withFolderNamedLikeImage_hasNoMediaType() {
        #expect(MockNode(handle: 1, name: "Album.jpg", nodeType: .folder).toNodeEntity().mediaType == nil)
        #expect(MockNode(handle: 2, name: "IMG1.jpg", nodeType: .file).toNodeEntity().mediaType == .image)
    }

    // MARK: - Helpers

    private func makeList(_ nodes: [NodeEntity]) -> NodeListEntity {
        .init(nodesCount: nodes.count, nodeAt: { nodes.indices.contains($0) ? nodes[$0] : nil })
    }

    private func file(_ name: String) -> NodeEntity {
        NodeEntity(name: name, handle: HandleEntity(name.hashValue.magnitude), isFile: true)
    }

    private func folder(_ name: String) -> NodeEntity {
        NodeEntity(name: name, handle: HandleEntity(name.hashValue.magnitude), isFolder: true)
    }
}
