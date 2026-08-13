import FileLink
import MEGADomain
import MEGASdk
import MEGASwift
import UIKit

/// Opens the file behind a file link in the viewer its type calls for.
///
/// The routing follows what the app did before the revamp, only from a tap instead of on arrival: the
/// old flow opened images and videos in the photo browser and audio in the player without ever showing
/// the file link screen, and kept the screen with its Open button for everything else.
final class FileLinkNodeOpener: FileLinkNodeOpenerProtocol {
    private weak var navigationController: UINavigationController?

    private let nodeProvider: FileLinkNodeProvider
    /// Set when the link the user opened was an encrypted one, of which the resolved link is the
    /// decrypted form. The viewers hand this one out when the file is shared onwards, so that the
    /// recipient gets the link as it was published.
    private let encryptedLink: String?

    init(
        navigationController: UINavigationController?,
        nodeProvider: FileLinkNodeProvider,
        encryptedLink: String?
    ) {
        self.navigationController = navigationController
        self.nodeProvider = nodeProvider
        self.encryptedLink = encryptedLink
    }

    func openNode(handle: HandleEntity) async {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        guard let node = await nodeProvider.node(for: handle),
              let link = nodeProvider.resolvedLink else { return }

        guard let navigationController, navigationController.presentedViewController == nil else { return }

        if node.isVisualMedia {
            presentPhotoBrowser(for: node, link: link, in: navigationController)
        } else if node.name?.fileExtensionGroup.isMultiMedia == true, node.mnz_isPlayable() {
            // Visual media is already handled above, so what is left of multimedia here is audio.
            presentAudioPlayer(for: node, link: link, in: navigationController)
        } else {
            // The document previewer, the text editor and Quick Look all sit behind this one, which
            // picks between them. `folderLink` is what makes it treat the file as shared by link
            // rather than as one of the user's own, as the legacy file link screen also asked for.
            node.mnz_open(
                in: navigationController,
                folderLink: true,
                fileLink: encryptedLink ?? link,
                messageId: nil,
                chatId: nil,
                isFromSharedItem: false,
                allNodes: nil
            )
        }
    }

    /// Presented on top of the file link screen rather than replacing it, so closing the file comes
    /// back to the file rather than out of the link altogether.
    private func presentPhotoBrowser(for node: MEGANode, link: String, in navigationController: UINavigationController) {
        let photoBrowser = MEGAPhotoBrowserViewController.photoBrowser(
            withMediaNodes: NSMutableArray(array: [node]),
            api: MEGASdk.shared,
            displayMode: DisplayMode.fileLink,
            isFromSharedItem: false,
            presenting: node
        )
        // The photo browser keeps the two apart itself, preferring the encrypted one when sharing.
        photoBrowser.publicLink = link
        if let encryptedLink {
            photoBrowser.encryptedLink = encryptedLink
        }
        navigationController.present(photoBrowser, animated: true)
    }

    private func presentAudioPlayer(for node: MEGANode, link: String, in navigationController: UINavigationController) {
        guard !MEGAChatSdk.shared.mnz_existsActiveCall else {
            Helper.cannotPlayContentDuringACallAlert()
            return
        }

        node.presentAudioPlayer(
            node: node,
            fileLink: encryptedLink ?? link,
            isFolderLink: false,
            presenter: navigationController.viewControllers.last,
            messageId: nil,
            chatId: nil,
            isFromSharedItem: false,
            allNodes: nil
        )
    }
}
