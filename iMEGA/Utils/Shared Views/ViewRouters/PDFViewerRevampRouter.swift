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
/// `.pdfPreviewRevamp` or `.iosPdfPreviewRevamp` feature flag is enabled.
/// Legacy `PreviewDocumentViewController` remains the fallback and keeps
/// handling non-PDF documents.
@objc final class PDFViewerRevampRouter: NSObject {
    /// Either flag is on and the extension is `pdf`, ignoring case.
    @objc static func canOpen(fileName: String) -> Bool {
        canOpen(
            fileName: fileName,
            featureFlagProvider: DIContainer.featureFlagProvider,
            remoteFeatureFlagUseCase: DIContainer.remoteFeatureFlagUseCase
        )
    }

    static func canOpen(
        fileName: String,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol
    ) -> Bool {
        let isFeatureEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .pdfPreviewRevamp)
            || remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosPdfPreviewRevamp)
        return isFeatureEnabled && fileName.pathExtension == "pdf"
    }

    /// Viewer for a PDF downloaded from `resolvedNode` as it is.
    /// - A folder-link or chat preview room node must already be authorised.
    @objc @MainActor static func viewControllerForResolvedNode(_ resolvedNode: MEGANode, context: DocumentPreviewContext) -> UIViewController {
        makeViewController(
            fileName: resolvedNode.name ?? "",
            pdfDocumentSource: .node(resolvedNode.toNodeEntity()),
            node: resolvedNode,
            context: context
        )
    }

    /// Viewer for a PDF that is already on disk (offline files / already-downloaded nodes).
    @objc @MainActor static func viewControllerForFilePath(_ filePath: String, node: MEGANode?, context: DocumentPreviewContext) -> UIViewController {
        makeViewController(
            fileName: node?.name ?? filePath.lastPathComponent,
            pdfDocumentSource: .local(URL(fileURLWithPath: filePath)),
            node: node,
            context: context
        )
    }

    // MARK: - Private

    @MainActor
    static func makeViewController(
        fileName: String,
        pdfDocumentSource: PDFViewerDocumentSource,
        node: MEGANode?,
        context: DocumentPreviewContext,
        lastPageUseCase: (any PDFViewerLastPageUseCaseProtocol)? = nil,
        activityPresenter: any PDFViewerActivityPresenting = PDFViewerActivityPresenter(),
        viewerFactory: @MainActor (PDFViewerView.Dependency) -> UIViewController = {
            PDFViewerViewController(dependency: $0)
        }
    ) -> UIViewController {
        if #available(iOS 26.0, *) {
            AppearanceManager.setTranslucentNavigationBar(for: [PDFViewerViewController.self])
        }

        weak var presentedViewer: UIViewController?
        weak var moreAnchor: UIView?
        weak var moreBarItem: UIBarButtonItem?
        weak var downloadAnchor: UIView?
        weak var downloadBarItem: UIBarButtonItem?

        let lastPageUseCase = lastPageUseCase ?? PDFViewerLastPageUseCase(
            repository: PDFViewerLastPageRepository(store: MEGAStore.shareInstance()),
            fingerprintRepository: PDFViewerDocumentFingerprintRepository(sdk: MEGASdk.shared)
        )
        let linkActions = DocumentPreviewLinkActionRouter(activityPresenter: activityPresenter)
        let localURL: URL? = if case .local(let url) = pdfDocumentSource {
            url
        } else {
            nil
        }

        let dependency = PDFViewerView.Dependency(
            actionContext: .init(
                hasNode: node != nil, isLink: context.isLink, isChat: context.chatId != nil
            ),
            pdfDocumentSource: pdfDocumentSource,
            downloadUseCase: makeDownloadNodeUseCase(node: node),
            lastPageUseCase: lastPageUseCase,
            leftOffItemRecordUseCase: LeftOffItemsRecordUseCase.shared,
            node: node?.toNodeEntity(),
            fileName: fileName,
            transferIndicatorToolbarFactory: TransferIndicatorBarItemConfigurator.toolbarFactory,
            onClose: { presentedViewer?.dismiss(animated: true) },
            moreMenuDependencies: .init(
                onTapped: { onPresented in
                    presentNodeActions(
                        for: node, from: presentedViewer, anchor: moreAnchor,
                        barItem: moreBarItem, context: context, linkActions: linkActions,
                        onPresented: onPresented
                    )
                },
                anchorReadyCallbacks: .init(
                    onViewReady: { moreAnchor = $0 },
                    onBarItemReady: { moreBarItem = $0 }
                )
            ),
            downloadDependencies: .init(
                onTapped: { onPresented in
                    activityPresenter.present(
                        fileURL: localURL, from: presentedViewer, anchor: downloadAnchor,
                        barItem: downloadBarItem, onPresented: onPresented
                    )
                },
                anchorReadyCallbacks: .init(
                    onViewReady: { downloadAnchor = $0 },
                    onBarItemReady: { downloadBarItem = $0 }
                )
            ),
            onLinkTapped: { url in
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            }
        )

        let viewer = viewerFactory(dependency)
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
