import Accounts
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGARepo
import SwiftUI

struct AccountMenuViewRouter {
    @MainActor
    func build() -> UIViewController {
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.sharedRepo
        )
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let viewModel = AccountMenuViewModel(
            currentUserSource: .shared,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase,
            fullNameHandler: { currentUserSource in
                currentUserSource.currentUser?.mnz_fullName ?? ""
            },
            avatarFetchHandler: { fullName, handle in
                guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
                    MEGALogError("base64 handle not found for handle \(handle)")
                    return nil
                }

                let backgroundColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle)

                let avatarHandler = UserAvatarHandler(
                    userImageUseCase: userImageUseCase,
                    initials: fullName.initialForAvatar(),
                    avatarBackgroundColor: UIColor.colorFromHexString(backgroundColor) ?? TokenColors.Icon.primary
                )

                return await avatarHandler.avatar(for: base64Handle)
            }
        )
        let hostingViewController = UIHostingController(
            rootView: AccountMenuView(viewModel: viewModel)
        )
        return MEGANavigationController(rootViewController: hostingViewController)
    }
}
