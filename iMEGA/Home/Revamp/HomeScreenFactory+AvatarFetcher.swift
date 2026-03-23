import Home
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import SwiftUI

extension HomeScreenFactory {
    func makeAvatarFetcher(
        userNameProvider: some UserNameProviderProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol
    ) -> (@Sendable () async -> Image?) {
        return { @Sendable [userNameProvider, userImageUseCase, megaHandleUseCase] () async -> Image? in
            await Self.fetchAvatar(
                currentUserSource: CurrentUserSource.shared,
                userNameProvider: userNameProvider,
                userImageUseCase: userImageUseCase,
                megaHandleUseCase: megaHandleUseCase
            )
        }
    }

    @MainActor
    private static func fetchAvatar(
        currentUserSource: CurrentUserSource,
        userNameProvider: some UserNameProviderProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol
    ) async -> Image? {
        let fullName: String = if let currentUser = currentUserSource.currentUser {
            userNameProvider.displayName(for: currentUser.toUserEntity()) ?? ""
        } else {
             ""
        }

        let handle: HandleEntity = currentUserSource.currentUserHandle ?? 0

        guard let base64Handle: Base64HandleEntity = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
            MEGALogError("base64 handle not found for handle \(handle)")
            return nil
        }

        let backgroundColor: String = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) ?? ""

        let avatarHandler: UserAvatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: fullName.initialForAvatar(),
            avatarBackgroundColor: UIColor.colorFromHexString(backgroundColor) ?? TokenColors.Icon.primary
        )

        let image: UIImage = await avatarHandler.avatar(for: base64Handle)
        return Image(uiImage: image)
    }

}
