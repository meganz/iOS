import FolderLink
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift
import UIKit

final class FolderLinkFileNodeOpener: FolderLinkFileNodeOpenerProtocol {
    weak var navigationController: UINavigationController?
    private let sdk = MEGASdk.sharedFolderLink
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func openNode(handle: HandleEntity, siblings: [HandleEntity]) {
        guard let megaNode = sdk.node(forHandle: handle) else { return }
        if megaNode.isVisualMedia {
            let authorizedMediaNodes = siblings.compactMap {
                if let node = sdk.node(forHandle: $0), node.isVisualMedia {
                    sdk.authorizeNode(node)
                } else {
                    nil
                }
            }
            let photoBrowser = MEGAPhotoBrowserViewController.photoBrowser(
                withMediaNodes: NSMutableArray(array: authorizedMediaNodes),
                api: sdk,
                displayMode: .nodeInsideFolderLink,
                isFromSharedItem: false,
                presenting: megaNode
            )
            navigationController?.present(photoBrowser, animated: true)
        } else {
            let allMegaNodes = siblings.compactMap { sdk.node(forHandle: $0) }
            megaNode.mnz_open(in: navigationController, folderLink: true, fileLink: nil, messageId: nil, chatId: nil, isFromSharedItem: false, allNodes: allMegaNodes)
        }
    }
}

extension MEGANode {
    var isVisualMedia: Bool {
        // A folder can carry an image or video extension in its name, so the name alone doesn't make it media
        if isFile(), let name {
            name.fileExtensionGroup.isVisualMedia
        } else {
            false
        }
    }
}
