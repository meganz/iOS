import FileLink
import MEGAAppSDKRepoMock
import Testing

@Suite("FileLinkNodeProvider Tests")
struct FileLinkNodeProviderTests {
    @Test("nothing is handed out before a link resolves")
    func node_beforeStoring_isNil() async {
        let sut = FileLinkNodeProvider()

        #expect(await sut.node(for: 42) == nil)
        #expect(sut.resolvedLink == nil)
    }

    @Test("the stored node is handed out for its own handle")
    func node_afterStoring_returnsNode() async {
        let sut = FileLinkNodeProvider()
        sut.store(MockNode(handle: 42), resolvedFrom: "link")

        #expect(await sut.node(for: 42)?.handle == 42)
    }

    @Test("a handle that is not the stored node's gets nothing")
    func node_otherHandle_isNil() async {
        let sut = FileLinkNodeProvider()
        sut.store(MockNode(handle: 42), resolvedFrom: "link")

        #expect(await sut.node(for: 7) == nil)
    }

    /// The link that resolved carries the decryption key even when the one the screen was opened with
    /// did not, so it is the one the viewers must be given.
    @Test("the link the node resolved from is kept with it")
    func resolvedLink_afterStoring_isTheLinkThatResolved() {
        let sut = FileLinkNodeProvider()
        sut.store(MockNode(handle: 42), resolvedFrom: "https://mega.nz/file/handle#key")

        #expect(sut.resolvedLink == "https://mega.nz/file/handle#key")
    }
}
