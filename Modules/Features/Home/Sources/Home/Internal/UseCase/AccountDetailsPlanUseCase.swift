@preconcurrency import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

protocol AccountDetailsPlanUseCaseProtocol: Sendable {
    var currentPlan: AnyAsyncSequence<AccountTypeEntity?> { get }
}

package final class AccountDetailsPlanUseCase: AccountDetailsPlanUseCaseProtocol, Sendable {

    private let accountUseCase: any AccountUseCaseProtocol
    private let planSubject: CurrentValueSubject<AccountTypeEntity?, Never>
    private let monitorTask: Task<Void, Never>

    package var currentPlan: AnyAsyncSequence<AccountTypeEntity?> {
        planSubject
            .removeDuplicates()
            .values
            .eraseToAnyAsyncSequence()
    }

    package init(
        accountUseCase: some AccountUseCaseProtocol,
        planPurchases: AnyAsyncSequence<Void> = NotificationCenter.purchaseSuccesses
    ) {
        self.accountUseCase = accountUseCase

        let subject = CurrentValueSubject<AccountTypeEntity?, Never>(
            accountUseCase.currentAccountDetails?.proLevel
        )
        self.planSubject = subject

        monitorTask = Task { [accountUseCase, planPurchases] in
            // Listen to payment success event, change AccountTypeEntity to nil
            // Consumer of this AccountTypeEntity can update their UI to `loading` state
            // and wait for the new values to arrive later
            async let purchaseMonitoring: () = {
                for await _ in planPurchases {
                    guard !Task.isCancelled else { break }
                    // Here we only need to change the value to nil to show the loading state,
                    // no need to proactively request for account updates because the
                    // purchase flow already handles that.
                    subject.send(nil)
                }
            }()

            // Note: This mimics the logic in `AccountMenuViewModel` to update plan
            // However this only works when user goes from Free to Pro, not the other way around.
            // Probably there's a bug in the SDK where `onAccountUpdate` is not triggered when Pro subscription expires.
            async let requestFinishMonitoring: () = {
                for await result in accountUseCase.onAccountRequestFinish {
                    guard !Task.isCancelled else { break }
                    guard Self.shouldRefreshPlan(for: result) else { continue }
                    subject.send(accountUseCase.currentAccountDetails?.proLevel)
                }
            }()

            _ = await (purchaseMonitoring, requestFinishMonitoring)
        }
    }

    deinit {
        monitorTask.cancel()
    }

    private static func shouldRefreshPlan(
        for result: Result<AccountRequestEntity, any Error>
    ) -> Bool {
        guard case .success(let request) = result else { return false }
        return request.type == .accountDetails
    }
}
