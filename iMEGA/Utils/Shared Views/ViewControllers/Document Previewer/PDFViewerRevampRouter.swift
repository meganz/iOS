import ChatRepo
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPDFViewer
import MEGAPreference
import MEGARepo

/// Routes PDF nodes to the revamped SwiftUI viewer (`MEGAPDFViewer`) when the
/// `.pdfPreviewRevamp` feature flag is enabled. Legacy `PreviewDocumentViewController`
/// remains the fallback and keeps handling non-PDF documents.
@objc final class PDFViewerRevampRouter: NSObject {
    @objc static var isEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .pdfPreviewRevamp)
    }

    /// Viewer for a PDF that still needs downloading (cloud drive / links).
    @objc @MainActor static func viewController(node: MEGANode, isLink: Bool, isFromSharedItem: Bool) -> UIViewController {
        makeViewController(
            fileName: node.name ?? "",
            pdfDocumentSource: .node(node.toNodeEntity()),
            isLink: isLink
        )
    }

    /// Viewer for a PDF that is already on disk (offline files / already-downloaded nodes).
    @objc @MainActor static func viewController(filePath: String, node: MEGANode?, isLink: Bool, isFromSharedItem: Bool) -> UIViewController {
        makeViewController(
            fileName: node?.name ?? filePath.lastPathComponent,
            pdfDocumentSource: .local(URL(fileURLWithPath: filePath)),
            isLink: isLink
        )
    }

    // MARK: - Private

    @MainActor
    private static func makeViewController(
        fileName: String,
        pdfDocumentSource: PDFViewerDocumentSource,
        isLink: Bool
    ) -> UIViewController {
        let dependency = PDFViewerView.Dependency(
            pdfDocumentSource: pdfDocumentSource,
            downloadUseCase: makeDownloadNodeUseCase(isLink: isLink),
            fileName: fileName,
            onLinkTapped: { url in
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            }
        )

        let viewer = PDFViewerViewController(dependency: dependency)
        viewer.modalPresentationStyle = .fullScreen
        return viewer
    }

    private static func makeDownloadNodeUseCase(isLink: Bool) -> some DownloadNodeUseCaseProtocol {
        let sdk = MEGASdk.shared
        let chatSdk = MEGAChatSdk.sharedChatSdk
        return DownloadNodeUseCase(
            downloadFileRepository: DownloadFileRepository(
                sdk: sdk,
                sharedFolderSdk: isLink ? MEGASdk.sharedFolderLink : nil,
                chatNodeProvider: ChatMEGANodeProvider(chatSdk: chatSdk, sdk: sdk)
            ),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            nodeRepository: NodeRepository.newRepo,
            nodeDataRepository: NodeDataRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            preferenceRepository: PreferenceRepository.newRepo,
            chatNodeRepository: ChatNodeRepository.newRepo,
            downloadChatRepository: DownloadChatRepository.newRepo
        )
    }
}
