import FileLink
import MEGADomain

final class MockFileLinkNodeOpener: FileLinkNodeOpenerProtocol {
    private(set) var openNodeCalledHandles: [HandleEntity] = []
    /// Runs while an open is in flight, so a test can act on the screen before it finishes.
    var whileOpening: (@MainActor () async -> Void)?

    func openNode(handle: HandleEntity) async {
        openNodeCalledHandles.append(handle)
        await whileOpening?()
    }
}
