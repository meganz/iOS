import Combine
import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI

final class ShareAttachmentCellViewModel: ObservableObject {
    private(set) var fileIcon: Image = MEGAAssetsImageProvider.image(named: .filetypeGeneric)
    private(set) var fileExtension: FileExtension = ""
    private let index: Int
    @Published var fileName = ""
    
    init(attachment: ShareAttachment, index: Int) {
        self.index = index
        setupContent(attachment)
    }
    
    private func setupContent(_ attachment: ShareAttachment) {
        let name = attachment.name ?? ""
        
        if attachment.type == .URL {
            fileIcon = MEGAAssetsImageProvider.image(named: .filetypeWebData)
            fileName = name
            fileExtension = ""
        } else {
            let extensionOfFile = name.pathExtension
            fileIcon = MEGAAssetsImageProvider.fileTypeResource(forFileExtension: extensionOfFile)
            fileExtension = extensionOfFile.isNotEmpty ? ".\(extensionOfFile)" : ""
            fileName = NSURL(fileURLWithPath: name).deletingPathExtension?.lastPathComponent ?? ""
        }
    }

    // MARK: - Public
    func saveNewFileName() {
        guard let attachments = ShareAttachment.attachmentsArray() as? [ShareAttachment],
              let attachment = attachments[safe: index],
              let trimmedFileName = fileName.trim else {
            return
        }

        let fullFileName = trimmedFileName + fileExtension
        attachment.name = fullFileName
    }
}
