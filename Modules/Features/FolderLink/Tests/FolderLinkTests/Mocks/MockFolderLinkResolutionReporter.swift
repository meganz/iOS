import FolderLink
import MEGADomain

final class MockFolderLinkResolutionReporter: FolderLinkResolutionReporting {
    private(set) var resolvedCalls: [(folderNode: NodeEntity, receivedLink: String)] = []
    private(set) var unavailableCalls: [String] = []

    func linkResolved(folderNode: NodeEntity, receivedLink: String) {
        resolvedCalls.append((folderNode, receivedLink))
    }

    func linkUnavailable(receivedLink: String) {
        unavailableCalls.append(receivedLink)
    }
}
