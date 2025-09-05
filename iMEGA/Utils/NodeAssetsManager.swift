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
            return image(for: node.name.pathExtension) ?? MEGAAssets.UIImage.filetypeGeneric
        case .folder:
            if MyChatFilesFolderNodeAccess.shared.isTargetNode(for: node) {
                return MEGAAssets.UIImage.folderChat
            }
            if CameraUploadNodeAccess.shared.isTargetNode(for: node) {
                return MEGAAssets.UIImage.filetypeFolderCamera
            }
            return commonFolderImage(for: node)
        case .incoming:
            return node.isFolder ? commonFolderImage(for: node) : MEGAAssets.UIImage.filetypeGeneric
        default:
            return MEGAAssets.UIImage.filetypeGeneric
        }
    }
    
    @objc func image(for extension: String) -> UIImage? {
        MEGAAssets.UIImage.image(forFileExtension: `extension`)
    }
            
    private func commonFolderImage(for node: NodeEntity) -> UIImage {
        if node.isInShare {
            return MEGAAssets.UIImage.folderUsers
        } else if node.isOutShare {
            return MEGAAssets.UIImage.folderUsers
        } else {
            return node.labelImage
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
