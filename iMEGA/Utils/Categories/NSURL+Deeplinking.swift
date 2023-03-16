import Foundation

enum DeeplinkPathKey: String {
    case file = "/file"
    case fileRequest = "/filerequest"
    case folder = "/folder"
    case confirmation = "/confirm"
    case newSignUp = "/newsignup"
    case backup = "/backup"
    case incomingPendingContacts = "/fm/ipc"
    case changeEmail = "/verify"
    case cancelAccount = "/cancel"
    case recover = "/recover"
    case contact = "/C"
    case openChatSection = "/fm/chat"
    case publicChat = "/chat"
    case loginrequired = "/loginrequired"
    case achievements = "/achievements"
    case newTextFile = "/newText"
    case privacyPolicy = "/privacy"
    case cookiePolicy = "/cookie"
    case termsOfService = "/terms"
}

enum DeeplinkFragmentKey: String {
    case file = "!"
    case folder = "F!"
    case confirmation = "confirm"
    case encrypted = "P!"
    case newSignUp = "newsignup"
    case backup = "backup"
    case incomingPendingContacts = "fm/ipc"
    case changeEmail = "verify"
    case cancelAccount = "cancel"
    case recover = "recover"
    case contact = "C!"
    case openChatSection = "fm/chat"
    case publicChat = "chat"

    // https://mega.nz/# + Base64Handle
    case handle
}

enum DeeplinkHostKey: String {

    case chatPeerOptions = "chatPeerOptions"
    case publicChat = "chat"
    
    case shortcutUpload = "widget.shortcut.uploadFile"
    case shortcutScanDocument = "widget.shortcut.scanDocument"
    case shortcutStartConversation = "widget.shortcut.startConversation"
    case shortcutAddContact = "widget.shortcut.addContact"
    case shortcutRecent = "widget.quickaccess.recents"
    case shortcutFavourites = "widget.quickaccess.favourites"
    case shortcutOffline = "widget.quickaccess.offline"
    // https://mega.nz/# + Base64Handle
    case handle
}

enum DeeplinkSchemeKey: String {
    case file = "file"
    case mega = "mega"
    case http = "https"
    case appsettings = "app-settings"
}

extension NSURL {
    @objc func mnz_type() -> URLType {
        guard let scheme = scheme else { return .default }
        
        switch DeeplinkSchemeKey(rawValue: scheme) {
        case .file:
            return .openInLink
        case .mega:
            return parseMEGASchemeURL()
        case .http:
            return parseUniversalLinkURL()
        case .appsettings:
            return .appSettings
        case .none:
            return .default
        }
    }
    
    private func parseFragmentType() -> URLType {
        guard let fragment = fragment  else {
            return .default
        }
        
        if fragment.hasPrefix(DeeplinkFragmentKey.file.rawValue) {
            return .fileLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.folder.rawValue) {
            return .folderLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.confirmation.rawValue) {
            return .confirmationLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.encrypted.rawValue) {
            return .encryptedLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.newSignUp.rawValue) {
            return .newSignUpLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.backup.rawValue) {
            return .backupLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.incomingPendingContacts.rawValue) {
            return .incomingPendingContactsLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.changeEmail.rawValue) {
            return .changeEmailLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.cancelAccount.rawValue) {
            return .cancelAccountLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.recover.rawValue) {
            return .recoverLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.contact.rawValue) {
            return .contactLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.openChatSection.rawValue) {
            return .openChatSectionLink
        } else if fragment.hasPrefix(DeeplinkFragmentKey.publicChat.rawValue) {
            return .publicChatLink
        } else if !fragment.isEmpty {
            return .handleLink
        }
        
        return .default
    }
    
    private func parseMEGASchemeURL() -> URLType {
 
        if host == DeeplinkHostKey.chatPeerOptions.rawValue {
            return .chatPeerOptionsLink
        } else if host == DeeplinkHostKey.publicChat.rawValue {
            return .publicChatLink
        } else if host == DeeplinkHostKey.shortcutUpload.rawValue {
            return .uploadFile
        } else if host == DeeplinkHostKey.shortcutScanDocument.rawValue {
            return .scanDocument
        } else if host == DeeplinkHostKey.shortcutStartConversation.rawValue {
            return .startConversation
        } else if host == DeeplinkHostKey.shortcutAddContact.rawValue {
            return .addContact
        }  else if host == DeeplinkHostKey.shortcutRecent.rawValue {
            return .showRecents
        } else if host == DeeplinkHostKey.shortcutFavourites.rawValue {
            guard let path = path, !path.isEmpty else { return .showFavourites }
            return .presentFavouritesNode
        } else if host == DeeplinkHostKey.shortcutOffline.rawValue  {
            guard let path = path, !path.isEmpty else { return .showOffline }
            return .presentOfflineFile
        }

        if fragment != nil {
            return parseFragmentType()
        }
        
        return .default
    }
    
    private func parseUniversalLinkURL() -> URLType {
        guard let path = path, host?.lowercased().contains("mega") == true else {
            return .default
        }
        
        if path.hasPrefix(DeeplinkPathKey.fileRequest.rawValue) {
            return .fileRequestLink
        } else if path.hasPrefix(DeeplinkPathKey.file.rawValue) {
            return .fileLink
        } else if path.hasPrefix(DeeplinkPathKey.folder.rawValue) {
            return .folderLink
        } else if path.hasPrefix(DeeplinkPathKey.confirmation.rawValue) {
            return .confirmationLink
        } else if path.hasPrefix(DeeplinkPathKey.newSignUp.rawValue) {
            return .newSignUpLink
        } else if path.hasPrefix(DeeplinkPathKey.backup.rawValue) {
            return .backupLink
        } else if path.hasPrefix(DeeplinkPathKey.incomingPendingContacts.rawValue) {
            return .incomingPendingContactsLink
        } else if path.hasPrefix(DeeplinkPathKey.changeEmail.rawValue) {
            return .changeEmailLink
        } else if path.hasPrefix(DeeplinkPathKey.cancelAccount.rawValue) {
            return .cancelAccountLink
        } else if path.hasPrefix(DeeplinkPathKey.recover.rawValue) {
            return .recoverLink
        } else if path.hasPrefix(DeeplinkPathKey.contact.rawValue) {
            return .contactLink
        } else if path.hasPrefix(DeeplinkPathKey.openChatSection.rawValue) {
            return .openChatSectionLink
        } else if path.hasPrefix(DeeplinkPathKey.publicChat.rawValue) {
            return .publicChatLink
        } else if path.hasPrefix(DeeplinkPathKey.loginrequired.rawValue) {
            return .loginRequiredLink
        } else if path.hasPrefix(DeeplinkPathKey.achievements.rawValue) {
            return .achievementsLink
        } else if path.hasPrefix(DeeplinkPathKey.newTextFile.rawValue) {
            return .newTextFile
        } else if path.hasPrefix(DeeplinkPathKey.privacyPolicy.rawValue) {
            return .default
        } else if path.hasPrefix(DeeplinkPathKey.cookiePolicy.rawValue) {
            return .default
        } else if path.hasPrefix(DeeplinkPathKey.termsOfService.rawValue) {
            return .default
        }
        
        if fragment != nil {
            return parseFragmentType()
        }
        
        return .default
    }
}
