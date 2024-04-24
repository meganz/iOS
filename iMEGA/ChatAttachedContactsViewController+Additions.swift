import MEGAL10n

extension ChatAttachedContactsViewController {
    @objc func titleForPromptWithCountOfContacts(_ numberOfContacts: Int) -> String {
        guard numberOfContacts > 0 else {
            return Strings.Localizable.select
        }
        return Strings.Localizable.Chat.Message.numberOfContacts(numberOfContacts)
    }
}
