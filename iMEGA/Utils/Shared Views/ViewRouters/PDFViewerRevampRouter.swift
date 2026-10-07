import ChatRepo
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPDFViewer
import MEGAPreference
import MEGARepo
import MEGASwift
import UIKit

/// Routes PDF nodes to the revamped SwiftUI viewer (`MEGAPDFViewer`) when the
/// `.pdfPreviewRevamp` feature flag is enabled. Legacy `PreviewDocumentViewController`
/// remains the fallback and keeps handling non-PDF documents.
@objc final class PDFViewerRevampRouter: NSObject {
    private static var isEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .pdfPreviewRevamp)
    }

    /// The flag is on and the extension is `pdf`, ignoring case.
    @objc static func canOpen(fileName: String) -> Bool {
        canOpen(fileName: fileName, isFeatureEnabled: isEnabled)
    }

    static func canOpen(fileName: String, isFeatureEnabled: Bool) -> Bool {
        isFeatureEnabled && fileName.pathExtension == "pdf"
    }

    /// Viewer for a PDF downloaded from `resolvedNode` as it is.
    /// - A folder-link or chat preview room node must already be authorised.
    @objc @MainActor static func viewControllerForResolvedNode(_ resolvedNode: MEGANode, isLink: Bool, isFromSharedItem: Bool) -> UIViewController {
        makeViewController(
            fileName: resolvedNode.name ?? "",
            pdfDocumentSource: .node(resolvedNode.toNodeEntity()),
            node: resolvedNode,
            isLink: isLink,
            isFromSharedItem: isFromSharedItem
        )
    }

    /// Viewer for a PDF that is already on disk (offline files / already-downloaded nodes).
    @objc @MainActor static func viewControllerForFilePath(_ filePath: String, node: MEGANode?, isLink: Bool, isFromSharedItem: Bool) -> UIViewController {
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
            downloadUseCase: makeDownloadNodeUseCase(node: node),
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

    private static func makeDownloadNodeUseCase(node: MEGANode?) -> some DownloadNodeUseCaseProtocol {
        DownloadNodeUseCase(
            downloadFileRepository: makeDownloadFileRepository(node: node),
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

    /// A repository that downloads `node` without an SDK tree lookup.
    static func makeDownloadFileRepository(
        node: MEGANode?,
        sdk: MEGASdk = .shared
    ) -> DownloadFileRepository {
        DownloadFileRepository(
            sdk: sdk,
            chatNodeProvider: ChatMEGANodeProvider(chatSdk: .sharedChatSdk, sdk: sdk),
            preresolvedNodes: node.map { [$0.handle: $0] } ?? [:]
        )
    }
}
