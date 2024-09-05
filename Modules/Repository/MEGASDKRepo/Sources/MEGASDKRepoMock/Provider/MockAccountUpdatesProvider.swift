import MEGADomain
import MEGASDKRepo
import MEGASwift

public struct MockAccountUpdatesProvider: AccountUpdatesProviderProtocol, Sendable {
    public var onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>>
    public var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]>
    public var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]>
    
    public init(
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.onAccountRequestFinish = onAccountRequestFinish
        self.onUserAlertsUpdates = onUserAlertsUpdates
        self.onContactRequestsUpdates = onContactRequestsUpdates
    }
}
