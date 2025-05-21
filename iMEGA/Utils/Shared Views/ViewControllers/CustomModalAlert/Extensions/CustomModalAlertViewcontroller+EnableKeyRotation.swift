import MEGAAssets
import MEGADomain
import MEGAL10n

extension CustomModalAlertViewController {
    func configureForEnableKeyRotation(in chatId: ChatIdEntity) {
        image = MEGAAssets.UIImage.lock
        viewTitle = Strings.Localizable.enableEncryptedKeyRotation
        detail = Strings.Localizable.keyRotationIsSlightlyMoreSecureButDoesNotAllowYouToCreateAChatLinkAndNewParticipantsWillNotSeePastMessages
        firstButtonTitle = Strings.Localizable.enable
        dismissButtonTitle = Strings.Localizable.cancel
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                MEGAChatSdk.shared.setPublicChatToPrivate(chatId)
            })
        }
    }
}
