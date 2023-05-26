import Combine
import MEGADomain
import MEGASwift

final class ShareAttachmentCellViewModel: ObservableObject {
    private(set) var fileIconName: String = ""
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
            fileIconName = NodeAssetsManager.shared.imageName(for: "html")
            fileName = name
            fileExtension = ""
        } else {
            let extensionOfFile = name.pathExtension
            fileIconName = NodeAssetsManager.shared.imageName(for: extensionOfFile)
            fileExtension = extensionOfFile.isNotEmpty ? ".\(extensionOfFile)" : ""
            fileName = NSURL(fileURLWithPath: name).deletingPathExtension?.lastPathComponent ?? ""
        }
    }

    //MARK: - Public
    func saveNewFileName() {
        guard let attachment = ShareAttachment.attachmentsArray().object(at: index) as? ShareAttachment,
              let fileName = fileName.trim else { return }
        let fullFileName = fileName + fileExtension
        attachment.name = fullFileName
    }
}
