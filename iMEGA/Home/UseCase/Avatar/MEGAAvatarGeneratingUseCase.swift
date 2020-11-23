import Foundation

protocol MEGAAvatarGeneratingUseCaseProtocol {

    func avatarName() -> String?

    func avatarBackgroundColorHex() -> String?
}

final class MEGAAavatarGeneratingUseCase: MEGAAvatarGeneratingUseCaseProtocol {

    private let storeUserClient: StoreUserClient

    private let meagAvatarClient: SDKAvatarClient

    private let megaUserClient: SDKUserClient

    init(
        storeUserClient: StoreUserClient,
        megaAvatarClient: SDKAvatarClient,
        megaUserClient: SDKUserClient
    ) {
        self.storeUserClient = storeUserClient
        self.meagAvatarClient = megaAvatarClient
        self.megaUserClient = megaUserClient
    }

    // MARK: - Generating Avatar Image

    func avatarName() -> String? {
        guard let userHandle = megaUserClient.currentUser()?.handle else {
            return nil
        }

        guard let displayName = storeUserClient.getUser(userHandle)?.displayName else {
            return nil
        }
        return (displayName as NSString).mnz_initialForAvatar()
    }

    func avatarBackgroundColorHex() -> String? {
        guard let userHandle = megaUserClient.currentUser()?.handle else {
            return nil
        }

        return meagAvatarClient.avatarBackgroundColorHex(userHandle)
    }
}
