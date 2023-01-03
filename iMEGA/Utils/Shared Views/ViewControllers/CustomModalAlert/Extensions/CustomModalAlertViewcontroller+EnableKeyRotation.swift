import MEGADomain

extension CustomModalAlertViewController {
    func configureForEnableKeyRotation(in chatId: ChatIdEntity) {
        image = Asset.Images.Chat.lock.image
        viewTitle = Strings.Localizable.enableEncryptedKeyRotation
        detail = Strings.Localizable.keyRotationIsSlightlyMoreSecureButDoesNotAllowYouToCreateAChatLinkAndNewParticipantsWillNotSeePastMessages
        firstButtonTitle = Strings.Localizable.enable
        dismissButtonTitle = Strings.Localizable.cancel
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                MEGASdkManager.sharedMEGAChatSdk().setPublicChatToPrivate(chatId)
            })
        }
    }
}
