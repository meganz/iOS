import MEGAL10n
import MEGAPresentation

extension ShareViewController {
    
    @objc func successSendToChatMessage(attachments: [ShareAttachment], receiverCount: Int) -> String {
        if attachments.count > 1 {
            let filesString = Strings.Localizable.General.Format.Count.file(attachments.count)
            return Strings.Localizable.Share.Message.SendToChat.withMultipleFiles(receiverCount)
                .replacingOccurrences(of: "[A]", with: filesString)
        } else {
            guard let attachment = attachments.first else { return "" }
            let attachmentName = attachment.name ?? ""
            return Strings.Localizable.Share.Message.SendToChat.withOneFile(receiverCount)
                .replacingOccurrences(of: "[A]", with: attachmentName)
        }
    }
}
