import MEGADomain

/// Rebuilds a public file link around the decryption key the user typed in.
///
/// Implemented outside the module because link building lives in the app layer.
public protocol FileLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}

/// Opens the file a link resolved to, in whichever viewer its type calls for.
///
/// Implemented outside the module because every destination -- the photo browser, the audio player,
/// the document previewer -- lives in the app layer.
///
/// Reaching the node behind the handle suspends, hence the `async`: a public link node is not part of
/// the account tree, so the app layer cannot look it up either. See `FileLinkNodeProvider`.
@MainActor
public protocol FileLinkNodeOpenerProtocol {
    func openNode(handle: HandleEntity) async
}

/// The actions the more button of the file link screen hands back to the app layer.
///
/// Share link is not among them: the sheet offers it through SwiftUI's `ShareLink`, which brings the
/// anchoring the system share sheet needs on iPad with it.
public enum FileLinkAction: Equatable, Sendable {
    case saveToMEGA
    case saveToPhotos
    case download
    case copyToOffline
    /// Carries the link because sending to chat passes the link on rather than acting on the file, and the
    /// form it passes on is the published one -- the same the Share link row hands to the share sheet.
    case sendToChat(String)
}

/// Runs the actions the file link screen offers.
///
/// Implemented outside the module because each of them ends up in a flow of the app layer's own: the node
/// browser, the share sheet, the transfer queue.
@MainActor
public protocol FileLinkActionHandlerProtocol {
    func handle(_ action: FileLinkAction, nodeHandle: HandleEntity) async
}
