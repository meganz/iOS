import Foundation
import MEGADomain

protocol MEGAAvatarGeneratingUseCaseProtocol {

    func avatarName() -> String?

    func avatarBackgroundColorHex() -> String?
}

final class MEGAAavatarGeneratingUseCase: MEGAAvatarGeneratingUseCaseProtocol {

    private let storeUserClient: StoreUserClient

    private let meagAvatarClient: SDKAvatarClient

    private let accountUseCase: AccountUseCaseProtocol

    init(
        storeUserClient: StoreUserClient,
        megaAvatarClient: SDKAvatarClient,
        accountUseCase: AccountUseCaseProtocol
    ) {
        self.storeUserClient = storeUserClient
        self.meagAvatarClient = megaAvatarClient
        self.accountUseCase = accountUseCase
    }

    // MARK: - Generating Avatar Image

    func avatarName() -> String? {
        guard let userHandle = accountUseCase.currentUserHandle else {
            return nil
        }

        guard let displayName = storeUserClient.getUser(userHandle)?.displayName else {
            return nil
        }
        return (displayName as NSString).mnz_initialForAvatar()
    }

    func avatarBackgroundColorHex() -> String? {
        guard let userHandle = accountUseCase.currentUserHandle else {
            return nil
        }

        return meagAvatarClient.avatarBackgroundColorHex(userHandle)
    }
}
