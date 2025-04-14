import MEGADomain
import MEGASwift

public final class MockContactLinkVerificationUseCase: ContactLinkVerificationUseCaseProtocol, @unchecked Sendable {
    public var qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void> {
        _qrCodeContactAutoAdditionEvents
    }
    public var contactLinksOptionResult: Result<Bool, any Error>
    public var updateContactLinksOption_calledTimes: Int = 0
    public var resetContactLink_calledTimes: Int = 0
    
    private var _qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void>
    
    public init(
        contactLinksOptionResult: Result<Bool, any Error> = .success(true),
        qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void> = EmptyAsyncSequence<Void>().eraseToAnyAsyncSequence()
    ) {
        self.contactLinksOptionResult = contactLinksOptionResult
        _qrCodeContactAutoAdditionEvents = qrCodeContactAutoAdditionEvents
    }
    
    public func contactLinksOption() async throws -> Bool {
        try contactLinksOptionResult.get()
    }
    
    public func updateContactLinksOption(enabled: Bool) async throws {
        updateContactLinksOption_calledTimes += 1
    }
    
    public func resetContactLink() async throws {
        resetContactLink_calledTimes += 1
    }
}
