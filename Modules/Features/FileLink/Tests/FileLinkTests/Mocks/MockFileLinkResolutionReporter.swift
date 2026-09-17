import FileLink
import MEGADomain

final class MockFileLinkResolutionReporter: FileLinkResolutionReporting {
    private(set) var linkResolvedCalledArguments: [(node: NodeEntity, receivedLink: String)] = []
    private(set) var linkUnavailableCalledLinks: [String] = []

    func linkResolved(node: NodeEntity, receivedLink: String) {
        linkResolvedCalledArguments.append((node, receivedLink))
    }

    func linkUnavailable(receivedLink: String) {
        linkUnavailableCalledLinks.append(receivedLink)
    }
}
