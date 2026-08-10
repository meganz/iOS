/// Rebuilds a public file link around the decryption key the user typed in.
///
/// Implemented outside the module because link building lives in the app layer.
public protocol FileLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}
