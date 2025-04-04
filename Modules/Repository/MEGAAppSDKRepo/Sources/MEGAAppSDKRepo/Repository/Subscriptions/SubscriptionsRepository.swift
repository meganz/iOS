import MEGADomain
import MEGASdk
import MEGASwift

public struct SubscriptionsRepository: SubscriptionRepositoryProtocol {
    public static var newRepo: SubscriptionsRepository {
        SubscriptionsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func cancelSubscriptions(reason: String?, subscriptionId subscriptionID: String?, canContact: Bool) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.creditCardCancelSubscriptions(
                reason,
                subscriptionId: subscriptionID,
                canContact: canContact,
                delegate: RequestDelegate(completion: { result in
                    switch result {
                    case .success: completion(.success)
                    case .failure: completion(.failure(AccountErrorEntity.generic))
                    }
                })
            )
        }
    }
    
    public func cancelSubscriptions(reasonList: [CancelSubscriptionReasonEntity]?, subscriptionId: String?, canContact: Bool) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.creditCardCancelSubscriptions(
                withReasons: reasonList.toMEGACancelSubscriptionReasonList(),
                subscriptionId: subscriptionId,
                canContact: canContact,
                delegate: RequestDelegate(completion: { result in
                    switch result {
                    case .success: completion(.success)
                    case .failure: completion(.failure(AccountErrorEntity.generic))
                    }
                })
            )
        }
    }
}
