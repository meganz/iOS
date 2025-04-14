import MEGASwift

public protocol ContactLinkVerificationRepositoryProtocol: RepositoryProtocol, Sendable {
    var qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void> { get }
    func contactLinksOption() async throws -> Bool
    func updateContactLinksOption(enabled: Bool) async throws
    func resetContactLink() async throws
}
