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
        icon(for: node.toNodeEntity())
    }
    
    func icon(for node: NodeEntity) -> UIImage {
        switch node.nodeType {
        case .file:
            return image(for: node.name.pathExtension)
        case .folder:
            if MyChatFilesFolderNodeAccess.shared.isTargetNode(for: node) {
                return UIImage.folderChat
            }
            if CameraUploadNodeAccess.shared.isTargetNode(for: node) {
                return UIImage.filetypeFolderCamera
            }
            return commonFolderImage(for: node)
        case .incoming:
            return node.isFolder ? commonFolderImage(for: node) : UIImage(resource: .filetypeGeneric)
        default:
            return UIImage(resource: .filetypeGeneric)
        }
    }
    
    @objc func image(for extension: String) -> UIImage {
        MEGAAssetsImageProvider.fileTypeResource(forFileExtension: `extension`)
    }
            
    private func commonFolderImage(for node: NodeEntity) -> UIImage {
        if node.isInShare {
            return UIImage.folderIncoming
        } else if node.isOutShare {
            return UIImage.folderOutgoing
        } else {
            return UIImage(resource: .filetypeFolder)
        }
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
