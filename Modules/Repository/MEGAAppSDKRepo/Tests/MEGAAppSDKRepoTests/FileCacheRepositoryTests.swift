import Foundation
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("FileCacheRepository - node names become single path components")
struct FileCacheRepositoryTests {
    private static let dotDot = String(repeating: ".", count: 2)
    private static let traversingName = [dotDot, dotDot, "Documents", "secret.txt"].joined(separator: "/")

    private static func makeSUT() -> FileCacheRepository {
        FileCacheRepository(fileManager: .default, sdk: MockSdk())
    }

    private static func makeNode(name: String, base64Handle: String = UUID().uuidString) -> NodeEntity {
        NodeEntity(name: name, handle: 1, base64Handle: base64Handle, isFile: true)
    }

    /// `true` when `url`, with `.` and `..` resolved, is directly inside `directory`.
    private static func isDirectChild(_ url: URL, of directory: URL) -> Bool {
        url.standardizedFileURL.deletingLastPathComponent().standardizedFileURL.path == directory.standardizedFileURL.path
    }

    @Test("A plain name is appended unchanged", arguments: ["report.pdf", "photo 1.jpg", "a:b.txt"])
    func plainName_isAppendedUnchanged(name: String) {
        let sut = Self.makeSUT()
        let node = Self.makeNode(name: name)

        #expect(sut.tempFileURL(for: node).lastPathComponent == name)
        #expect(Self.isDirectChild(sut.tempFileURL(for: node), of: sut.base64HandleTempFolder(for: node.base64Handle)))
    }

    @Test("A name holding path separators or dots stays inside its folder", arguments: [traversingName, dotDot, "."])
    func hostileName_staysInsideItsFolder(name: String) {
        let sut = Self.makeSUT()
        let node = Self.makeNode(name: name)
        let folder = sut.base64HandleTempFolder(for: node.base64Handle)

        let url = sut.tempFileURL(for: node)
        #expect(Self.isDirectChild(url, of: folder))
        #expect(!url.lastPathComponent.contains("/"))
        #expect(url.lastPathComponent != Self.dotDot && url.lastPathComponent != ".")
    }

    @Test("The staging copy and the original image cache use the same escaped name")
    func stagingAndOriginalImage_useEscapedName() {
        let sut = Self.makeSUT()
        let node = Self.makeNode(name: Self.traversingName)

        let staging = sut.stagingTempFileURL(for: node)
        #expect(Self.isDirectChild(staging, of: sut.stagingTempFolder(for: node)))
        #expect(staging.lastPathComponent == sut.tempFileURL(for: node).lastPathComponent)

        let original = sut.cachedOriginalImageURL(for: node)
        let originalFolder = sut.cachedOriginalImageDirectoryURL.appendingPathComponent(node.base64Handle, isDirectory: true)
        #expect(Self.isDirectChild(original, of: originalFolder))
        #expect(original.lastPathComponent == staging.lastPathComponent)
    }

    @Test("A name that resolves to an existing location outside the folder is not reported as cached")
    func existingTempFileURL_doesNotMatchOutsideTheFolder() {
        let sut = Self.makeSUT()
        // Without escaping, `<tmp>/<handle>/..` is the temp folder itself, which always exists.
        let node = Self.makeNode(name: Self.dotDot)

        #expect(sut.existingTempFileURL(for: node) == nil)
    }

    @Test("A cached file under the escaped name is found")
    func existingTempFileURL_findsEscapedFile() throws {
        let sut = Self.makeSUT()
        let node = Self.makeNode(name: Self.dotDot)
        let url = sut.tempFileURL(for: node)
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(sut.existingTempFileURL(for: node) == url)
    }
}
