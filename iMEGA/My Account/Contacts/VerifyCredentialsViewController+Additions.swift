
extension VerifyCredentialsViewController {
    
    @objc func setContentMessages() {
        if isVerifyContactForSharedItem {
            navigationItem.title = Strings.Localizable.verifyCredentials
            myCredentialsHeaderLabel.text = Strings.Localizable.SharedItems.ContactVerification.Section.MyCredentials.message
            contactHeaderLabel.text = isIncomingSharedItem ?
            Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.Receiver.message:
            Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.Owner.message
        } else {
            navigationItem.title = Strings.Localizable.verifyCredentials
            myCredentialsHeaderLabel.text = Strings.Localizable.thisIsBestDoneInRealLife
            contactHeaderLabel.text = ""
        }
    }
}
