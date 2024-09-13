import MEGAChatSdk
import MEGADomain
import MEGASwift

public struct SessionUpdateRepository: SessionUpdateRepositoryProtocol {
    public static var newRepo: SessionUpdateRepository {
        SessionUpdateRepository(sessionUpdateProvider: SessionUpdateProvider(sdk: .sharedChatSdk))
    }
    
    private let sessionUpdateProvider: any SessionUpdateProviderProtocol

    public init(sessionUpdateProvider: some SessionUpdateProviderProtocol) {
        self.sessionUpdateProvider = sessionUpdateProvider
    }
    
    public var sessionUpdate: AnyAsyncSequence<(ChatSessionEntity, CallEntity)> {
        sessionUpdateProvider.sessionUpdate
    }
}
