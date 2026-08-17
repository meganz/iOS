@preconcurrency import Combine

import Foundation
import MEGADomain
import MEGASwift

package enum AccountStorageDetails: Sendable, Equatable {
    case limited(_ storageUsed: Int64, storageMax: Int64, storageStatus: StorageStatusEntity)
    case unlimited(_ storageUsed: Int64)
}

protocol AccountDetailsStorageUseCaseProtocol: Sendable {
    var storageDetails: AnyAsyncSequence<AccountStorageDetails?> { get }
}

package final class AccountDetailsStorageUseCase: AccountDetailsStorageUseCaseProtocol, @unchecked Sendable {
    private let accountUseCase: any AccountUseCaseProtocol

    private let storageSubject: CurrentValueSubject<AccountStorageDetails?, Never>
    private let monitorTask: Task<Void, Never>

    package var storageDetails: AnyAsyncSequence<AccountStorageDetails?> {
        storageSubject
            .removeDuplicates()
            .values
            .eraseToAnyAsyncSequence()
    }

    package init(
        accountUseCase: some AccountUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        planPurchases: AnyAsyncSequence<Void> = NotificationCenter.purchaseSuccesses
    ) {
        self.accountUseCase = accountUseCase

        let initialDetails: AccountStorageDetails? = {
            guard let details =  accountUseCase.currentAccountDetails else { return nil }
            return AccountDetailsStorageUseCase.storageDetails(from: details, storageStatus: accountStorageUseCase.currentStorageStatus)
        }()
        let subject = CurrentValueSubject<AccountStorageDetails?, Never>(initialDetails)
        self.storageSubject = subject

        monitorTask = Task { [accountUseCase, planPurchases] in
            // Listen to payment success event, change AccountStorageDetails to nil
            // Consumer of this AccountStorageDetails can update their UI to `loading` state
            // and wait for the new values to arrive later
            async let purchaseMonitoring: () = {
                for await _ in planPurchases {
                    guard !Task.isCancelled else { break }
                    subject.send(nil)
                }
            }()

            async let requestFinishMonitoring: () = {
                for await _ in accountStorageUseCase.storageSumUpdates {
                    guard !Task.isCancelled else { break }
                    guard let accountDetails = accountUseCase.currentAccountDetails else { continue }
                    let storageState = try? await accountStorageUseCase.refreshCurrentStorageState()
                    subject.send(AccountDetailsStorageUseCase.storageDetails(from: accountDetails, storageStatus: storageState))
                }
            }()

            async let accountRequestFinishMonitoring: () = {
                for await result in accountUseCase.onAccountRequestFinish {
                    guard !Task.isCancelled else { break }
                    guard Self.shouldRefreshStorage(for: result) else { continue }
                    guard let accountDetails = accountUseCase.currentAccountDetails else { continue }
                    let storageState = try? await accountStorageUseCase.refreshCurrentStorageState()
                    subject.send(AccountDetailsStorageUseCase.storageDetails(from: accountDetails, storageStatus: storageState))
                }
            }()

            _ = await (purchaseMonitoring, requestFinishMonitoring, accountRequestFinishMonitoring)
        }

    }

    deinit {
        monitorTask.cancel()
    }

    private static func storageDetails(from accountDetails: AccountDetailsEntity, storageStatus: StorageStatusEntity?) -> AccountStorageDetails {
        if accountDetails.proLevel == .business || accountDetails.proLevel == .proFlexi {
            let storageUsed = accountDetails.storageUsed
            return .unlimited(storageUsed)
        } else {
            let storageUsed = accountDetails.storageUsed
            let storageMax = accountDetails.storageMax
            return .limited(storageUsed, storageMax: storageMax, storageStatus: storageStatus ?? .noStorageProblems)
        }
    }

    private static func shouldRefreshStorage(
        for result: Result<AccountRequestEntity, any Error>
    ) -> Bool {
        guard case .success(let request) = result,
              request.type == .accountDetails
        else { return false }

        return true
    }
}
