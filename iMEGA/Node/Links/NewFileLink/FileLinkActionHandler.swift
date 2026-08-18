import FileLink
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import UIKit

/// Runs the actions the more options sheet of the file link screen offers.
///
/// The ones that act on the file reach it through `FileLinkNodeProvider`: a public link node is not part
/// of the account tree, so neither the SDK nor this class can look it up by handle. Saving to Photos and
/// copying to Offline are given the link instead of the node -- the SDK resolves it again for them -- and
/// it has to be the link that resolved, key included when the user had to type it in. Sending to chat
/// passes on a link rather than acting on the file, so the sheet hands that one in with the action.
final class FileLinkActionHandler: FileLinkActionHandlerProtocol {
    private weak var navigationController: UINavigationController?

    private let nodeProvider: FileLinkNodeProvider
    /// Set while an export is in flight, so that picking Download again over the top of one does not end
    /// up with two share sheets
    private var isExporting = false
    /// Held here because the chat picker only keeps a weak reference to it.
    private var sendLinkDelegate: SendLinkToChatsDelegate?

    init(navigationController: UINavigationController?, nodeProvider: FileLinkNodeProvider) {
        self.navigationController = navigationController
        self.nodeProvider = nodeProvider
    }

    func handle(_ action: FileLinkAction, nodeHandle: HandleEntity) async {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        guard let node = await nodeProvider.node(for: nodeHandle),
              let link = nodeProvider.resolvedLink,
              let navigationController else { return }

        switch action {
        case .saveToMEGA:
            // Signs the user in first when they are not, and dismisses this screen on its way to the node
            // browser, as the legacy file link screen also did.
            ImportLinkRouter(isFolderLink: false, nodes: [node], presenter: navigationController).start()
        case .saveToPhotos:
            saveToPhotos(link: link)
        case .download:
            await export(node: node, in: navigationController)
        case .copyToOffline:
            copyToOffline(link: link, in: navigationController)
        case let .sendToChat(shareLink):
            sendToChat(link: shareLink, in: navigationController)
        }
    }

    private func saveToPhotos(link: String) {
        guard let linkURL = URL(string: link) else { return }

        SaveToPhotosCoordinator
            .customProgressSVGErrorMessageDisplay(
                configureProgress: {
                    TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                })
            .saveToPhotos(fileLink: FileLinkEntity(linkURL: linkURL))
    }

    /// Signs the user in first when they are not: the Offline section belongs to an account.
    private func copyToOffline(link: String, in navigationController: UINavigationController) {
        guard let linkURL = URL(string: link) else { return }

        DownloadLinkRouter(link: linkURL, isFolderLink: false, presenter: navigationController).start()
    }

    /// Sends the link rather than the file: the recipient gets a message carrying the link, which is why
    /// this is the one action that needs no node.
    ///
    /// Without a session there is nobody to send from, so the link is put aside for the onboarding flow to
    /// pick the chat once the user has signed in, as the legacy screen did.
    private func sendToChat(link: String, in navigationController: UINavigationController) {
        guard SAMKeychain.password(forService: "MEGA", account: "sessionV3") != nil else {
            MEGALinkManager.linkSavedString = link
            MEGALinkManager.selectedOption = .sendNodeLinkToChat
            navigationController.pushViewController(OnboardingUSPViewController(), animated: true)
            DIContainer.tracker.trackAnalyticsEvent(with: SendToChatFileLinkNoAccountLoggedButtonPressedEvent())
            return
        }

        guard let sendToChatNavigationController = UIStoryboard(name: "Chat", bundle: nil)
            .instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = sendToChatNavigationController.viewControllers.first as? SendToViewController else {
            return
        }

        sendToViewController.sendMode = .fileAndFolderLink
        sendLinkDelegate = SendLinkToChatsDelegate(link: link)
        sendToViewController.sendToViewControllerDelegate = sendLinkDelegate

        navigationController.present(sendToChatNavigationController, animated: true)
        DIContainer.tracker.trackAnalyticsEvent(with: SendToChatFileLinkButtonPressedEvent())
    }

    /// Saving to the device goes through the system share sheet, where Save to Files lives. The node is
    /// downloaded first, which is what the export waits on -- hence holding `isExporting` for the whole
    /// run rather than only while it is being set up.
    private func export(node: MEGANode, in navigationController: UINavigationController) async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        await ExportFileRouter(
            presenter: navigationController,
            sender: navigationController.view,
            nodeProvider: nodeProvider
        )
        .export(node: node.toNodeEntity())?.value
    }
}
