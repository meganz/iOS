import FileLink
import MEGAAppSDKRepoMock
import Testing

@Suite("FileLinkNodeProvider Tests")
struct FileLinkNodeProviderTests {
    @Test("nothing is handed out before a link resolves")
    func node_beforeStoring_isNil() async {
        let sut = FileLinkNodeProvider()

        #expect(await sut.node(for: 42) == nil)
    }

    @Test("the stored node is handed out for its own handle")
    func node_afterStoring_returnsNode() async {
        let sut = FileLinkNodeProvider()
        sut.store(MockNode(handle: 42))

        #expect(await sut.node(for: 42)?.handle == 42)
    }

    @Test("a handle that is not the stored node's gets nothing")
    func node_otherHandle_isNil() async {
        let sut = FileLinkNodeProvider()
        sut.store(MockNode(handle: 42))

        #expect(await sut.node(for: 7) == nil)
    }
}
