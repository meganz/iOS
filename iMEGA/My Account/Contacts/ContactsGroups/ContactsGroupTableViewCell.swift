import ChatRepo
import MEGADesignToken
import MEGADomain
import MEGASDKRepo
import UIKit

class ContactsGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var backAvatarImage: UIImageView!
    @IBOutlet weak var frontAvatarImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var keyRotationImage: UIImageView!
    
    private var viewModel: ContactsGroupCellViewModel?
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateStyle(with: traitCollection)
            configureAvatarImages()
        }
    }
    
    func configure(
        with chatListItem: ChatListItemEntity
    ) {
        viewModel = ContactsGroupCellViewModel(
            chatListItem: chatListItem,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )
        
        titleLabel.text = viewModel?.title
        keyRotationImage.isHidden = viewModel?.isKeyRotationImageHidden ?? false
        
        configureAvatarImages()
    }
    
    private func configureAvatarImages() {
        guard let viewModel = viewModel else { return }
        
        backAvatarImage.mnz_setImage(forUserHandle: viewModel.backAvatarHandle)
        frontAvatarImage.mnz_setImage(forUserHandle: viewModel.frontAvatarHandle)
        frontAvatarImage.borderColor = .mnz_backgroundElevated(traitCollection)
    }
    
    private func updateStyle(with trait: UITraitCollection) {
        titleLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.label
    }
}
