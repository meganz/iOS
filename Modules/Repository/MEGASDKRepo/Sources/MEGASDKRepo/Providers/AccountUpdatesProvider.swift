import MEGADomain
import MEGASdk
import MEGASwift

public protocol AccountUpdatesProviderProtocol: Sendable {
    /// Account updates from `MEGARequestDelegate` `onRequestFinish` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `Result<AccountRequestEntity, any Error>` until sequence terminated
    var onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> { get }
    
    /// User alert updates from `MEGAGlobalDelegate` `onUserAlertsUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `[UserAlertEntity]` until sequence terminated
    var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> { get }

    /// User alert updates from `MEGAGlobalDelegate` `onContactRequestsUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `[ContactRequestEntity]` until sequence terminated
    var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> { get }
}

public struct AccountUpdatesProvider: AccountUpdatesProviderProtocol {
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public var onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> {
        AsyncStream { continuation in
            let delegate = AccountRequestDelegate(onRequestFinish: { requestResult in
                continuation.yield(requestResult)
            })
            
            continuation.onTermination = { _ in
                sdk.remove(delegate as (any MEGARequestDelegate))
            }
            sdk.add(delegate as (any MEGARequestDelegate))
        }
        .eraseToAnyAsyncSequence()
    }
    
    public var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> {
        AsyncStream { continuation in
            let delegate = AccountRequestDelegate(onUserAlertsUpdate: { alerts in
                continuation.yield(alerts)
            })
            
            continuation.onTermination = { _ in
                sdk.remove(delegate as (any MEGAGlobalDelegate))
            }
            sdk.add(delegate as (any MEGAGlobalDelegate))
        }
        .eraseToAnyAsyncSequence()
    }
    
    public var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> {
        AsyncStream { continuation in
            let delegate = AccountRequestDelegate(onContactRequestsUpdate: { contactRequests in
                continuation.yield(contactRequests)
            })
            
            continuation.onTermination = { _ in
                sdk.remove(delegate as (any MEGAGlobalDelegate))
            }
            sdk.add(delegate as (any MEGAGlobalDelegate))
        }
        .eraseToAnyAsyncSequence()
    }
}

// MARK: - AccountRequestDelegate
private final class AccountRequestDelegate: NSObject {
    private let onRequestFinish: (Result<AccountRequestEntity, any Error>) -> Void
    private let onUserAlertsUpdate: ([UserAlertEntity]) -> Void
    private let onContactRequestsUpdate: ([ContactRequestEntity]) -> Void
    
    init(
        onRequestFinish: @escaping (Result<AccountRequestEntity, any Error>) -> Void = {_ in },
        onUserAlertsUpdate: @escaping ([UserAlertEntity]) -> Void = {_ in },
        onContactRequestsUpdate: @escaping ([ContactRequestEntity]) -> Void = {_ in }
    ) {
        self.onRequestFinish = onRequestFinish
        self.onUserAlertsUpdate = onUserAlertsUpdate
        self.onContactRequestsUpdate = onContactRequestsUpdate
        super.init()
    }
}

extension AccountRequestDelegate: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else {
            onRequestFinish(.failure(error))
            return
        }
        onRequestFinish(.success(request.toAccountRequestEntity()))
    }
}

extension AccountRequestDelegate: MEGAGlobalDelegate {
    public func onUserAlertsUpdate(_ api: MEGASdk, userAlertList: MEGAUserAlertList) {
        onUserAlertsUpdate(userAlertList.toUserAlertEntities())
    }
    
    public func onContactRequestsUpdate(_ api: MEGASdk, contactRequestList: MEGAContactRequestList) {
        onContactRequestsUpdate(contactRequestList.toContactRequestEntities())
    }
}
