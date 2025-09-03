import Foundation
import MEGAL10n
import SwiftUI

struct ShortcutDetail: Hashable {
    let title: String
    let imageName: String
    let topBackgroundColor: Color
    let bottomBackgroundColor: Color
    let link: String
    
    static let uploadFile = ShortcutDetail(title: Strings.Localizable.uploadFile, imageName: "uploadFileWidgetXL", topBackgroundColor: Color("#00A886"), bottomBackgroundColor: Color("#008A6E"), link: "mega://widget.shortcut.uploadFile")

    static let scanDocument = ShortcutDetail(title: Strings.Localizable.scanDocument, imageName: "scanDocumentWidgetXL", topBackgroundColor: Color("#F9B35F"), bottomBackgroundColor: Color("#E68F4D"), link: "mega://widget.shortcut.scanDocument")

    static let startConversation = ShortcutDetail(title: Strings.Localizable.startConversation, imageName: "startConversationWidgetXL", topBackgroundColor: Color("#02A2FF"), bottomBackgroundColor: Color("#0274CC"), link: "mega://widget.shortcut.startConversation")

    static let addContact = ShortcutDetail(title: Strings.Localizable.addContact, imageName: "addContactWidgetXL", topBackgroundColor: Color("#00B0C4"), bottomBackgroundColor: Color("#0095A6"), link: "mega://widget.shortcut.addContact")
    
    static let availableShortcuts = [uploadFile, scanDocument, startConversation, addContact]
    
    static let defaultShortcut = ShortcutDetail.uploadFile
}
