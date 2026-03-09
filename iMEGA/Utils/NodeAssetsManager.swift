import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGARepo

@objc final class NodeAssetsManager: NSObject {
    @objc static let shared = NodeAssetsManager(sdk: .shared)
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    @objc func icon(for node: MEGANode) -> UIImage {
        icon(
            for: node.toNodeEntity(),
            hasOutgoingOrPendingShare: hasOutgoingOrPendingShare(for: node)
        )
    }
    
    func icon(for node: NodeEntity) -> UIImage {
        icon(
            for: node,
            hasOutgoingOrPendingShare: hasOutgoingOrPendingShare(for: node)
        )
    }
    
    private func icon(for node: NodeEntity, hasOutgoingOrPendingShare: Bool) -> UIImage {
        switch node.nodeType {
        case .file:
            return image(for: node.name.pathExtension) ?? MEGAAssets.UIImage.filetypeGeneric
        case .folder:
            return folderImage(for: node, hasOutgoingOrPendingShare: hasOutgoingOrPendingShare)
        case .incoming:
            return node.isFolder ? commonFolderImage(for: node, hasOutgoingShare: hasOutgoingOrPendingShare) : MEGAAssets.UIImage.filetypeGeneric
        default:
            return MEGAAssets.UIImage.filetypeGeneric
        }
    }
    
    @objc func image(for extension: String) -> UIImage? {
        MEGAAssets.UIImage.image(forFileExtension: `extension`)
    }
    
    private func folderImage(for node: NodeEntity, hasOutgoingOrPendingShare: Bool) -> UIImage {
        if MyChatFilesFolderNodeAccess.shared.isTargetNode(for: node) {
            return MEGAAssets.UIImage.folderChat
        }
        if CameraUploadNodeAccess.shared.isTargetNode(for: node) {
            return MEGAAssets.UIImage.filetypeFolderCamera
        }
        return commonFolderImage(for: node, hasOutgoingShare: hasOutgoingOrPendingShare)
    }
            
    private func commonFolderImage(for node: NodeEntity, hasOutgoingShare: Bool) -> UIImage {
        if node.isInShare {
            return MEGAAssets.UIImage.folderUsers
        } else if hasOutgoingShare {
            return MEGAAssets.UIImage.folderUsers
        } else {
            return node.labelImage
        }
    }
    
    private func hasOutgoingOrPendingShare(for node: NodeEntity) -> Bool {
        guard node.isFolder else { return false }
        if node.isOutShare {
            return true
        }
        guard let megaNode = sdk.node(forHandle: node.handle) else { return false }
        return megaNode.mnz_hasPendingOrActiveOutShares()
    }
    
    private func hasOutgoingOrPendingShare(for node: MEGANode) -> Bool {
        guard node.isFolder() else { return false }
        return node.isOutShare() || node.mnz_hasPendingOrActiveOutShares()
    }
}

extension NodeAssetsManager: NodeIconRepositoryProtocol {
    func iconData(for node: MEGADomain.NodeEntity) -> Data {
        guard let icon = icon(for: node).pngData() else {
            return Data()
        }
        return icon
    }
}
