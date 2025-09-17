import Foundation
import MEGADomain
import MEGAAppPresentation
import MEGAAnalyticsiOS

extension MEGANode {
    @objc func trackFileOpenAnalytics(
        isFolderLink: Bool = false,
        fileLink: String? = nil,
        isFromChat: Bool = false,
        isFromSharedItem: Bool = false,
        isFromRecent: Bool = false
    ) {
        guard let fileName = self.name,
              let fileType = detectDocumentFileType(from: fileName) else {
            return
        }
        
        let context = detectOpenContext(
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            isFromChat: isFromChat,
            isFromSharedItem: isFromSharedItem,
            isFromRecent: isFromRecent
        )

        DIContainer.tracker.trackAnalyticsEvent(
            with: FileOpenEvent(
                fileType: fileType,
                context: context
            )
        )
    }

    private func detectDocumentFileType(from fileName: String) -> String? {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        let documentFileExtensions = [
            "pdf" ,"txt" ,"json" ,"csv" ,"doc", "docx" ,"ppt", "pptx", "xml", "csv", "md", "yaml"
        ]
        if documentFileExtensions.contains(fileExtension) {
            return fileExtension
        } else {
            return nil
        }
    }

    private func detectOpenContext(
        isFolderLink: Bool = false,
        fileLink: String? = nil,
        isFromChat: Bool = false,
        isFromSharedItem: Bool = false,
        isFromRecent: Bool = false
    ) -> FileOpen.FileOpenContext {
        if isFolderLink {
            .folderlink
        } else if fileLink != nil {
            .filelink
        } else if isFromChat {
            .chat
        } else if isFromSharedItem {
            .shareditems
        } else if isFromRecent {
            .recent
        } else {
            .clouddrive
        }
    }
}
