import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGASdk
import UIKit

@MainActor
protocol DocumentPreviewLinkActionRouting {
    func importNode(_ node: MEGANode, isFolderLink: Bool, from presenter: UIViewController)
    func downloadFolderLinkNodes(_ nodes: [MEGANode], from presenter: UIViewController)
    func downloadFileLink(_ link: String, from presenter: UIViewController)
    func shareFileLink(_ link: String, from presenter: UIViewController, sender: Any)
    func sendToChat(_ node: MEGANode, fileLink: String?, from presenter: UIViewController)
}

@objc final class DocumentPreviewContext: NSObject {
    let isLink: Bool
    let fileLink: String?
    let isFromSharedItem: Bool
    let chatId: HandleEntity?
    let messageId: HandleEntity?

    var isFolderLink: Bool { isLink && fileLink == nil }

    @objc init(isLink: Bool, fileLink: String?, isFromSharedItem: Bool) {
        self.isLink = isLink
        self.fileLink = fileLink
        self.isFromSharedItem = isFromSharedItem
        chatId = nil
        messageId = nil
    }

    @objc init(chatId: HandleEntity, messageId: HandleEntity) {
        self.chatId = chatId
        self.messageId = messageId
        isLink = false
        fileLink = nil
        isFromSharedItem = false
    }
}

@MainActor final class DocumentPreviewLinkActionRouter: DocumentPreviewLinkActionRouting {
    typealias ImportRouterFactory = @MainActor (
        Bool, [MEGANode], UIViewController, Bool
    ) -> any ImportLinkRouting

    private let importRouterFactory: ImportRouterFactory
    private let activityPresenter: any PDFViewerActivityPresenting
    private var fileLinkDelegate: FileLinkActionViewControllerDelegate?

    init(
        importRouterFactory: @escaping ImportRouterFactory = {
            ImportLinkRouter(
                isFolderLink: $0, nodes: $1, presenter: $2, dismissBeforePresent: $3
            )
        },
        activityPresenter: some PDFViewerActivityPresenting = PDFViewerActivityPresenter()
    ) {
        self.importRouterFactory = importRouterFactory
        self.activityPresenter = activityPresenter
    }

    func importNode(_ node: MEGANode, isFolderLink: Bool, from presenter: UIViewController) {
        importRouterFactory(isFolderLink, [node], presenter, false).start()
    }

    func downloadFolderLinkNodes(_ nodes: [MEGANode], from presenter: UIViewController) {
        DownloadLinkRouter(
            nodes: nodes.toNodeEntities(), isFolderLink: true, presenter: presenter
        ).start()
    }

    func downloadFileLink(_ link: String, from presenter: UIViewController) {
        guard let url = URL(string: link) else { return }
        DownloadLinkRouter(link: url, isFolderLink: false, presenter: presenter).start()
    }

    func shareFileLink(_ link: String, from presenter: UIViewController, sender: Any) {
        activityPresenter.presentLink(link, from: presenter, sender: sender)
    }

    func sendToChat(_ node: MEGANode, fileLink: String?, from presenter: UIViewController) {
        if let fileLink {
            let delegate = FileLinkActionViewControllerDelegate(
                link: fileLink, viewController: presenter
            )
            fileLinkDelegate = delegate
            delegate.sendToChat()
        } else if CredentialUseCase(repo: CredentialRepository.newRepo).hasSession() {
            node.mnz_sendToChat(in: presenter)
        } else {
            MEGALinkManager.linkSavedString = ""
            MEGALinkManager.selectedOption = .sendNodeLinkToChat
            let onboarding = OnboardingUSPViewController()
            if let navigation = presenter.navigationController {
                navigation.pushViewController(onboarding, animated: true)
            } else {
                let navigation = MEGANavigationController(rootViewController: onboarding)
                navigation.addRightCancelButton()
                presenter.present(navigation, animated: true)
            }
        }
    }
}
