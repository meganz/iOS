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
        cell.avatarView.avatarImageView.layer.cornerRadius = cell.avatarView.avatarImageView.frame.size.width / 2
        cell.avatarView.avatarImageView.layer.masksToBounds = true
        
        if item.isGroup {
            guard let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: item.handle) else { return }
            cell.avatarView.setup(for: chatRoom)
        } else {
            Task {
                cell.avatarView.avatarImageView.image = await fetchUserAvatar(for: item)
            }
            
            cell.avatarView.configure(mode: .single)
        }
        
        guard let user = item.user, MEGASdk.shared.isContactVerificationWarningEnabled
        else {
            cell.contactVerifiedImageView.isHidden = true
            return
        }
        
        cell.contactVerifiedImageView.isHidden = !MEGASdk.shared.areCredentialsVerified(of: user)
    }
    
    private func fetchUserAvatar(for item: ItemListModel) async -> UIImage? {
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: item.handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            MEGALogDebug("Contacts list: base64 handle not found for handle \(item.handle)")
            return nil
        }
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository.newRepo,
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let avatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: item.name.initialForAvatar(),
            avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? MEGAAppColor.Black._000000.uiColor
        )
        
        return await avatarHandler.avatar(for: base64Handle)
    }
}
