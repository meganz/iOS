import MEGAChatSdk
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASdk
import MEGASDKRepo

extension ItemListViewController {
    @objc func setupCell(
        _ cell: ItemCollectionViewCell,
        with item: ItemListModel
    ) {
        cell.nameLabel.text = item.name

        if item.isGroup {
            guard let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: item.handle) else { return }
            cell.avatarView.setup(for: chatRoom)
        } else {
            fetchUserAvatar(
                for: item,
                completion: { image in
                    cell.avatarView.avatarImageView.image = image
                }
            )

            cell.avatarView.configure(mode: .single)
        }

        guard let user = item.user,
              DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .contactVerification)
        else {
            cell.contactVerifiedImageView.isHidden = true
            return
        }

        cell.contactVerifiedImageView.isHidden = !MEGASdk.shared.areCredentialsVerified(of: user)
    }

    private func fetchUserAvatar(for item: ItemListModel, completion: @escaping (UIImage) -> Void) {
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)

        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: item.handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            MEGALogDebug("Contacts list: base64 handle not found for handle \(item.handle)")
            return
        }

        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdk.shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )

        userImageUseCase.fetchUserAvatar(withUserHandle: item.handle,
                                         base64Handle: base64Handle,
                                         avatarBackgroundHexColor: avatarBackgroundHexColor,
                                         name: item.name) { result in
            switch result {
            case .success(let image):
                completion(image)
            case .failure(let error):
                MEGALogDebug("Contacts list: failed to fetch avatar for \(base64Handle) - \(error)")
            }
        }
    }
}
