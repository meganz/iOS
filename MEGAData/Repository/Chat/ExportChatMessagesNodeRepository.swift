
import Foundation

extension ExportChatMessagesRepository {
    static let `default` = ExportChatMessagesRepository(sdk: MEGASdkManager.sharedMEGASdk(), chatSdk: MEGASdkManager.sharedMEGAChatSdk(), store: MEGAStore.shareInstance())
}

class ExportChatMessagesRepository: ExportChatMessagesRepositoryProtocol {
    private let sdk: MEGASdk
    private let chatSdk: MEGAChatSdk
    private let store: MEGAStore

    init(sdk: MEGASdk, chatSdk: MEGAChatSdk, store: MEGAStore) {
        self.sdk = sdk
        self.chatSdk = chatSdk
        self.store = store
    }
    
    func exportText(message: MEGAChatMessage) -> URL? {
        let userName = chatSdk.userFullnameFromCache(byUserHandle: message.userHandle) ?? ""
        let messageTimestamp = message.timestamp?.string(withDateFormat: "dd/MM/yyyy HH:mm")
        let messageContent = message.content ?? ""
        let content = "[\(messageTimestamp ?? "")]#\(userName): \(messageContent)\n"
        
        let messageFilePath = NSTemporaryDirectory() + "Message \(message.messageId).txt"
        if (FileManager.default.createFile(atPath: messageFilePath, contents: content.data(using: .utf8), attributes: nil)) {
            return URL(fileURLWithPath: messageFilePath)
        } else {
            return nil
        }
    }
    
    func exportContact(message: MEGAChatMessage, contactAvatarImage: String?) -> URL? {
        let cnMutableContact = CNMutableContact()
        
        let userHandle = message.userHandle(at: 0)
        
        if let moUser = store.fetchUser(withUserHandle: userHandle),
           let firstname = moUser.firstname,
           let lastname = moUser.lastname {
            cnMutableContact.givenName = firstname
            cnMutableContact.familyName = lastname
        } else {
            cnMutableContact.givenName = message.userName(at: 0) ?? ""
        }
        
        let userEmail1 = (message.userEmail(at: 0) ?? "")as NSString
        cnMutableContact.emailAddresses = [CNLabeledValue.init(label: CNLabelHome, value: userEmail1)]
        
        if let avatarFilePath = contactAvatarImage, let avatarImage = UIImage(contentsOfFile: avatarFilePath) {
            cnMutableContact.imageData = avatarImage.jpegData(compressionQuality: 1)
        }
        
        do {
            var vCardData = try CNContactVCardSerialization.data(with: [cnMutableContact])
            var vCardString = String(data: vCardData, encoding: .utf8)
            if let base64Image = cnMutableContact.imageData?.base64EncodedString(),
               !base64Image.isEmpty {
                let vCardImageString = "PHOTO;TYPE=JPEG;ENCODING=BASE64:" + base64Image + "\n"
                let endvCardString = vCardImageString + "END:VCARD"
                vCardString = vCardString?.replacingOccurrences(of: "END:VCARD", with: endvCardString)
            }
            vCardData = vCardString?.data(using: .utf8) ?? vCardData
            
            do {
                if let fullName = message.userName(at: 0) {
                    let vCardFilename = fullName + ".vcf"
                    let vCardPath = NSTemporaryDirectory() + vCardFilename
                    let vCardURL = URL(fileURLWithPath: vCardPath)
                    
                    try vCardData.write(to: vCardURL, options: Data.WritingOptions.atomic)
                    
                    return vCardURL
                }
            } catch let error as NSError {
                MEGALogError("Could not write to vCard with error \(error)")
            }
        } catch let error as NSError {
            MEGALogError("Could not create vCard representation of the specified contacts with error \(error)")
        }
        return nil
    }
}
