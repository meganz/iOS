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
