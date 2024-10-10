import Foundation
import MEGAAnalyticsiOS
import MEGAPresentation

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
    case recover = "/recover" // when parking an account
    case contact = "/C"
    case openChatSection = "/fm/chat"
    case publicChat = "/chat"
    case scheduleChat = "/chats-meetings"
    case loginrequired = "/loginrequired"
    case achievements = "/achievements"
    case newTextFile = "/newText"
    case privacyPolicy = "/privacy"
    case cookiePolicy = "/cookie"
    case termsOfService = "/terms"
    case collection = "/collection"
    case recovery = "/recovery" // whe tapping forgot password
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
    case collection
    case publicChat = "chat"
    
    case shortcutUpload = "widget.shortcut.uploadFile"
    case shortcutScanDocument = "widget.shortcut.scanDocument"
    case shortcutStartConversation = "widget.shortcut.startConversation"
    case shortcutAddContact = "widget.shortcut.addContact"
    case shortcutRecent = "widget.quickaccess.recents"
    case shortcutFavourites = "widget.quickaccess.favourites"
    case shortcutOffline = "widget.quickaccess.offline"
    case upgrade
    case presentNode = "presentNode"
    // https://mega.nz/# + Base64Handle
    case handle
    case vpn
}

enum DeeplinkSchemeKey: String {
    case file = "file"
    case mega = "mega"
    case http = "https"
    case appsettings = "app-settings"
    case vpn = "megavpn"
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
        case .vpn:
            return .vpn
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
        switch host {
        case DeeplinkHostKey.chatPeerOptions.rawValue:
            return .chatPeerOptionsLink
        case DeeplinkHostKey.collection.rawValue:
            return .collection
        case DeeplinkHostKey.publicChat.rawValue:
            return .publicChatLink
        case DeeplinkHostKey.shortcutUpload.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: ShortcutWidgetUploadFileButtonPressedEvent())
            return .uploadFile
        case DeeplinkHostKey.shortcutScanDocument.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: ShortcutWidgetScanDocumentButtonPressedEvent())
            return .scanDocument
        case DeeplinkHostKey.shortcutStartConversation.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: ShortcutWidgetStartConversationButtonPressedEvent())
            return .startConversation
        case DeeplinkHostKey.shortcutAddContact.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: ShortcutWidgetAddContactButtonPressedEvent())
            return .addContact
        case DeeplinkHostKey.shortcutRecent.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: QuickAccessWidgetRecentsPressedEvent())
            return .showRecents
        case DeeplinkHostKey.shortcutFavourites.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: QuickAccessWidgetFavouritesPressedEvent())
            guard let path = path, !path.isEmpty else { return .showFavourites }
            return .presentFavouritesNode
        case DeeplinkHostKey.shortcutOffline.rawValue:
            DIContainer.tracker.trackAnalyticsEvent(with: QuickAccessWidgetOffilePressedEvent())
            guard let path = path, !path.isEmpty else { return .showOffline }
            return .presentOfflineFile
        case DeeplinkHostKey.presentNode.rawValue:
            return .presentNode
        case DeeplinkHostKey.upgrade.rawValue:
            return .upgrade
        case DeeplinkHostKey.vpn.rawValue:
            return .vpn
        default:
            if fragment != nil {
                return parseFragmentType()
            }
            return .default
        }
    }
    
    private func parseUniversalLinkURL() -> URLType {
        guard let path, host?.lowercased().contains("mega") == true else {
            return .default
        }
        
        if path.hasPrefix(DeeplinkPathKey.recovery.rawValue) && path.count > DeeplinkPathKey.recovery.rawValue.count {
            return .recoverLink
        }
        
        let prefixes: [(key: DeeplinkPathKey, urlType: URLType)] = [
            (DeeplinkPathKey.fileRequest, .fileRequestLink),
            (DeeplinkPathKey.file, .fileLink),
            (DeeplinkPathKey.folder, .folderLink),
            (DeeplinkPathKey.confirmation, .confirmationLink),
            (DeeplinkPathKey.newSignUp, .newSignUpLink),
            (DeeplinkPathKey.backup, .backupLink),
            (DeeplinkPathKey.incomingPendingContacts, .incomingPendingContactsLink),
            (DeeplinkPathKey.changeEmail, .changeEmailLink),
            (DeeplinkPathKey.cancelAccount, .cancelAccountLink),
            (DeeplinkPathKey.recovery, .default), // need to be added before "recover", otherwise link will be identifier ad recover
            (DeeplinkPathKey.recover, .recoverLink),
            (DeeplinkPathKey.contact, .contactLink),
            (DeeplinkPathKey.openChatSection, .openChatSectionLink),
            (DeeplinkPathKey.scheduleChat, .scheduleChatLink),
            (DeeplinkPathKey.publicChat, .publicChatLink),
            (DeeplinkPathKey.loginrequired, .loginRequiredLink),
            (DeeplinkPathKey.achievements, .achievementsLink),
            (DeeplinkPathKey.newTextFile, .newTextFile),
            (DeeplinkPathKey.privacyPolicy, .default),
            (DeeplinkPathKey.cookiePolicy, .default),
            (DeeplinkPathKey.termsOfService, .default),
            (DeeplinkPathKey.collection, .collection)
        ]
        
        if let match = prefixes.first(where: { path.hasPrefix($0.key.rawValue) }) {
            return match.urlType
        }
        
        if fragment != nil {
            return parseFragmentType()
        }
        
        return .default
    }
}
