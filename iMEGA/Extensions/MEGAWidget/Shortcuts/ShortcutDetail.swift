import Foundation
import SwiftUI

struct ShortcutDetail: Hashable {
    let title: String
    let imageName: String
    let topBackgroundColor: Color
    let bottomBackgroundColor: Color
    let link: String
    
    static let uploadFile = ShortcutDetail(title: NSLocalizedString("Upload File", comment: "Text to indicate the action of uploading a file to the cloud drive") , imageName: "uploadFileWidgetXL", topBackgroundColor: Color("#00A886"), bottomBackgroundColor: Color("#008A6E") , link: "mega://widget.shortcut.uploadFile")

    static let scanDocument = ShortcutDetail(title: NSLocalizedString("Scan Document", comment: "Menu option from the `Add` section that allows the user to scan document and upload it directly to MEGA."), imageName: "scanDocumentWidgetXL", topBackgroundColor: Color("#F9B35F"), bottomBackgroundColor: Color("#E68F4D"), link: "mega://widget.shortcut.scanDocument")

    static let startConversation = ShortcutDetail(title: NSLocalizedString("startConversation", comment: "start a chat/conversation"), imageName: "startConversationWidgetXL", topBackgroundColor: Color("#02A2FF"), bottomBackgroundColor: Color("#0274CC"), link: "mega://widget.shortcut.startConversation")

    static let addContact = ShortcutDetail(title: NSLocalizedString("addContact", comment: "Button title shown in empty views when you can 'Add contacts'"), imageName: "addContactWidgetXL", topBackgroundColor: Color("#00B0C4"), bottomBackgroundColor: Color("#0095A6"), link: "mega://widget.shortcut.addContact")
    
    static let availableShortcuts = [uploadFile, scanDocument, startConversation, addContact]
    
    static let defaultShortcut = ShortcutDetail.uploadFile
}
