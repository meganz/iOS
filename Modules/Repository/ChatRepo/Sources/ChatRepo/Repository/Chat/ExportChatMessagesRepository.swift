import Contacts
import Foundation
import MEGAChatSdk
import MEGADomain
import UIKit

public final class ExportChatMessagesRepository: ExportChatMessagesRepositoryProtocol {
    public static var newRepo: ExportChatMessagesRepository {
        ExportChatMessagesRepository(chatSdk: .sharedChatSdk)
    }

    private let chatSdk: MEGAChatSdk

    init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func exportText(message: ChatMessageEntity) -> URL? {
        let userName = chatSdk.userFullnameFromCache(byUserHandle: message.userHandle) ?? ""
        let messageTimestamp = message.timestamp?.string(with: "dd/MM/yyyy HH:mm")
        let messageContent = message.content ?? ""
        let content = "[\(messageTimestamp ?? "")]#\(userName): \(messageContent)\n"
        
        let messageFilePath = NSTemporaryDirectory() + "Message \(message.messageId).txt"
        if FileManager.default.createFile(atPath: messageFilePath, contents: content.data(using: .utf8), attributes: nil) {
            return URL(fileURLWithPath: messageFilePath)
        } else {
            return nil
        }
    }
    
    public func exportContact(
        message: ChatMessageEntity,
        contactAvatarImage: String?,
        userFirstName: String?,
        userLastName: String?
    ) -> URL? {
        let cnMutableContact = CNMutableContact()
        
        guard let peer = message.peers.first else {
            return nil
        }
        
        if let firstname = userFirstName,
           let lastname = userLastName {
            cnMutableContact.givenName = firstname
            cnMutableContact.familyName = lastname
        } else {
            cnMutableContact.givenName = peer.name ?? ""
        }
        
        let userEmail1 = (peer.email ?? "") as NSString
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
                if let fullName = peer.name {
                    let vCardFilename = fullName + ".vcf"
                    let vCardPath = NSTemporaryDirectory() + vCardFilename
                    let vCardURL = URL(fileURLWithPath: vCardPath)
                    
                    try vCardData.write(to: vCardURL, options: Data.WritingOptions.atomic)
                    
                    return vCardURL
                }
            } catch {
                return nil
            }
        } catch {
            return nil
        }
        return nil
    }
}

private extension Date {
    func string(with dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
}
