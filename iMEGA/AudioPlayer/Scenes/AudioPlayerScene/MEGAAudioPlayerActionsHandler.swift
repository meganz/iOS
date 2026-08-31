import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAudioPlayer
import MEGADomain
import MEGASDKRepo
import UIKit

/// Builds the closure that `MEGAAudioPlayerViewRouter` invokes when the user
/// taps the three-dot button on the revamped audio player.
@MainActor
enum MEGAAudioPlayerActionsHandler {
    private static var offlineActionGuard: OfflineActionGuard {
        OfflineActionGuard(isNewOfflineModeEnabled: DIContainer.featureFlagProvider.isNewOfflineModeEnabled)
    }

    static func make() -> MEGAAudioPlayerViewRouter.ActionsHandler {
        { hostVC, track in
            switch track {
            case .account(let node):
                presentAccountNodeAction(for: node, on: hostVC)
            case .folderLink(let node):
                presentFolderLinkNodeAction(for: node, on: hostVC)
            case .fileLink(let url, _):
                presentFileLinkAction(for: url, on: hostVC)
            case .offlineNode(let node, _):
                // Played from disk, but still a cloud node
                presentAccountNodeAction(for: node, on: hostVC)
            case .offline:
                // The Offline screen's files stand for no node
                break
            }
        }
    }

    private static func presentAccountNodeAction(for nodeEntity: NodeEntity, on hostVC: UIViewController) {
        guard let node = MEGASdk.sharedSdk.node(forHandle: nodeEntity.handle) else { return }
        let isBackupNode = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ).isBackupNode(nodeEntity)
        present(
            node: node,
            on: hostVC,
            displayMode: node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive,
            isBackupNode: isBackupNode,
            isNodeFromFolderLink: false
        )
    }

    /// The track carries the node the folder link SDK authorized at enqueue time
    private static func presentFolderLinkNodeAction(for playableNode: any PlayableNode, on hostVC: UIViewController) {
        guard let node = playableNode as? MEGANode else { return }
        present(
            node: node,
            on: hostVC,
            displayMode: .nodeInsideFolderLink,
            isBackupNode: false,
            isNodeFromFolderLink: true
        )
    }

    private static func present(
        node: MEGANode,
        on hostVC: UIViewController,
        displayMode: DisplayMode,
        isBackupNode: Bool,
        isNodeFromFolderLink: Bool
    ) {
        let delegate = OfflineAwareNodeActionDelegate(
            wrapping: NodeActionViewControllerGenericDelegate(
                viewController: hostVC,
                isNodeFromFolderLink: isNodeFromFolderLink,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: hostVC)
            ),
            offlineActionGuard: offlineActionGuard
        )
        let vc = PortraitNodeActionViewController(
            node: node,
            delegate: delegate,
            displayMode: displayMode,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: hostVC
        )
        hostVC.present(vc, animated: true)
    }

    private static func presentFileLinkAction(for url: URL, on hostVC: UIViewController) {
        let link = url.absoluteString
        Task { @MainActor [weak hostVC] in
            let node: MEGANode? = await withCheckedContinuation { continuation in
                MEGASdk.sharedSdk.publicNode(forMegaFileLink: link, delegate: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        continuation.resume(returning: request.publicNode)
                    case .failure:
                        continuation.resume(returning: nil)
                    }
                })
            }
            guard let node, let hostVC else { return }
            let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive
            let delegate = OfflineAwareNodeActionDelegate(
                wrapping: FileLinkActionViewControllerDelegate(link: link, viewController: hostVC),
                offlineActionGuard: offlineActionGuard
            )
            let vc = PortraitNodeActionViewController(
                node: node,
                delegate: delegate,
                displayMode: displayMode,
                isInVersionsView: false,
                isBackupNode: false,
                isFromSharedItem: false,
                isAudioFileLink: true,
                sender: hostVC
            )
            hostVC.present(vc, animated: true)
        }
    }
}
