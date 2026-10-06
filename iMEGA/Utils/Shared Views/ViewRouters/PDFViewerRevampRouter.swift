import ChatRepo
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPDFViewer
import MEGAPreference
import MEGARepo
import UIKit

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
            node: node,
            isLink: isLink,
            isFromSharedItem: isFromSharedItem
        )
    }

    /// Viewer for a PDF that is already on disk (offline files / already-downloaded nodes).
    @objc @MainActor static func viewController(filePath: String, node: MEGANode?, isLink: Bool, isFromSharedItem: Bool) -> UIViewController {
        makeViewController(
            fileName: node?.name ?? filePath.lastPathComponent,
            pdfDocumentSource: .local(URL(fileURLWithPath: filePath)),
            node: node,
            isLink: isLink,
            isFromSharedItem: isFromSharedItem
        )
    }

    // MARK: - Private

    @MainActor
    private static func makeViewController(
        fileName: String,
        pdfDocumentSource: PDFViewerDocumentSource,
        node: MEGANode?,
        isLink: Bool,
        isFromSharedItem: Bool
    ) -> UIViewController {
        if #available(iOS 26.0, *) {
            AppearanceManager.setTranslucentNavigationBar(for: [PDFViewerViewController.self])
        }

        weak var presentedViewer: UIViewController?

        var onMoreTapped: (@MainActor () -> Void)?
        if let node {
            onMoreTapped = {
                guard let presentedViewer else { return }
                presentNodeActions(
                    for: node,
                    from: presentedViewer,
                    isLink: isLink,
                    isFromSharedItem: isFromSharedItem
                )
            }
        }

        let dependency = PDFViewerView.Dependency(
            pdfDocumentSource: pdfDocumentSource,
            downloadUseCase: makeDownloadNodeUseCase(isLink: isLink),
            fileName: fileName,
            transferIndicatorToolbarFactory: TransferIndicatorBarItemConfigurator.toolbarFactory,
            onClose: { presentedViewer?.dismiss(animated: true) },
            onMoreTapped: onMoreTapped,
            onLinkTapped: { url in
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            }
        )

        let viewer = PDFViewerViewController(dependency: dependency)
        presentedViewer = viewer
        let navigationController = MEGANavigationController(rootViewController: viewer)
        navigationController.modalPresentationStyle = .fullScreen
        return navigationController
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
