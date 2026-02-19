@preconcurrency import Combine

import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

package protocol AccountDetailsUserNameUseCaseProtocol: Sendable {
    var names: AnyAsyncSequence<String> { get }
}

package final class AccountDetailsUserNameUseCase: AccountDetailsUserNameUseCaseProtocol, @unchecked Sendable {
    private let currentUserSource: CurrentUserSource
    private let accountUseCase: any AccountUseCaseProtocol
    private let fullNameHandler: @Sendable (CurrentUserSource) -> String

    private let nameSubject: CurrentValueSubject<String, Never>
    private let monitorTask: Task<Void, Never>

    package var names: AnyAsyncSequence<String> {
        nameSubject
            .removeDuplicates()
            .values
            .eraseToAnyAsyncSequence()
    }

    package init(
        currentUserSource: CurrentUserSource,
        accountUseCase: some AccountUseCaseProtocol,
        fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String
    ) {
        self.currentUserSource = currentUserSource
        self.accountUseCase = accountUseCase
        self.fullNameHandler = fullNameHandler

        let subject: CurrentValueSubject<String, Never> = CurrentValueSubject(fullNameHandler(currentUserSource))
        self.nameSubject = subject

        monitorTask = Task { [accountUseCase, currentUserSource, fullNameHandler] in
            for await result in accountUseCase.onAccountRequestFinish {
                guard !Task.isCancelled else { break }
                guard Self.shouldRefreshName(for: result) else { continue }
                // `fullNameHandler` underlying implementation accesses CoreData therefore we need to wrap it with @MainActor
                let nameTask = Task { @MainActor in
                    fullNameHandler(currentUserSource)
                }

                subject.send(await nameTask.value)
            }
        }
    }

    deinit {
        monitorTask.cancel()
    }

    private static func shouldRefreshName(
        for result: Result<AccountRequestEntity, any Error>
    ) -> Bool {
        guard case .success(let request) = result,
              request.type == .getAttrUser,
              request.email == nil,  // own-user attribute, not a contact's
              let attribute = request.userAttribute,
              attribute == .firstName || attribute == .lastName
        else { return false }

        return true
    }
}
