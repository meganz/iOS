import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

package protocol AccountDetailsUserNameUseCaseProtocol: Sendable {
    var names: AnyAsyncSequence<String> { get async }
}

package final class AccountDetailsUserNameUseCase: AccountDetailsUserNameUseCaseProtocol, @unchecked Sendable {
    private let currentUserSource: CurrentUserSource
    private let accountUseCase: any AccountUseCaseProtocol
    private let userNameProvider: any UserNameProviderProtocol

    package var names: AnyAsyncSequence<String> {
        get async {
            accountUseCase.onAccountRequestFinish
                .filter { self.shouldRefreshName(for: $0) }
                .compactMap { _ -> String? in
                    guard let user = self.currentUserSource.currentUser?.toUserEntity() else { return nil }
                    return await self.userNameProvider.displayName(for: user)
                }
                .prepend(await self.initialName)
                .removeDuplicates()
                .eraseToAnyAsyncSequence()
        }
    }

    package init(
        currentUserSource: CurrentUserSource,
        accountUseCase: some AccountUseCaseProtocol,
        userNameProvider: some UserNameProviderProtocol
    ) {
        self.currentUserSource = currentUserSource
        self.accountUseCase = accountUseCase
        self.userNameProvider = userNameProvider
    }

    private var initialName: String {
        get async {
            guard let user = currentUserSource.currentUser?.toUserEntity() else {
                return ""
            }
            return await userNameProvider.displayName(for: user) ?? ""
        }

    }

    private func shouldRefreshName(
        for result: Result<AccountRequestEntity, any Error>
    ) -> Bool {
        guard case .success(let request) = result else { return false }
        let nameAttributeChanged = request.type == .getAttrUser
            && request.email == nil
        && (request.userAttribute == .firstName || request.userAttribute == .lastName)

        /*
        Aside from name change, we should also listen to .fetchNodes request because there are situation
        where name is not available intially and then later becomes available (e.g: Launching the app when
        there's no internet then internet recovers), .fetchNodes is the entry point where user data is available for display
         */
        return nameAttributeChanged || request.type == .fetchNodes
    }
}
