import MEGASwift

public protocol ContactLinkVerificationUseCaseProtocol: Sendable {
    /// An async sequence that emits an event whenever a MEGA user is auto-added to the contact list due to scanning the QR code.
    var qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void> { get }
    
    func contactLinksOption() async throws -> Bool
    func updateContactLinksOption(enabled: Bool) async throws
    func resetContactLink() async throws
}

public struct ContactLinkVerificationUseCase: ContactLinkVerificationUseCaseProtocol {
    private let repository: any ContactLinkVerificationRepositoryProtocol
    
    public init(repository: some ContactLinkVerificationRepositoryProtocol) {
        self.repository = repository
    }
    
    public var qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void> {
        repository.qrCodeContactAutoAdditionEvents
    }
    
    public func contactLinksOption() async throws -> Bool {
        try await repository.contactLinksOption()
    }
    
    public func updateContactLinksOption(enabled: Bool) async throws {
        try await repository.updateContactLinksOption(enabled: enabled)
    }
    
    public func resetContactLink() async throws {
        try await repository.resetContactLink()
    }
}
