import MEGAAppSDKRepo
import MEGASwift

@MainActor
struct SetVideoPlayerItemMetadataCommand {
    
    private let playerItem: AVPlayerItem
    private let node: MEGANode
    private let fileManager: FileManager
    private let sdk: MEGASdk
    private let nodeAssetManager: NodeAssetsManager
    
    init(playerItem: AVPlayerItem, node: MEGANode, fileManager: FileManager = .default, sdk: MEGASdk = .shared, nodeAssetManager: NodeAssetsManager = .shared) {
        self.playerItem = playerItem
        self.node = node
        self.fileManager = fileManager
        self.sdk = sdk
        self.nodeAssetManager = nodeAssetManager
    }
    
    func execute() async {
        setPlayerItemTitleMetadata()
        await setPlayerItemThumbnailMetadata()
    }
    
    private func setPlayerItemTitleMetadata() {
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = node.name as? NSString
        
        playerItem.externalMetadata = [titleItem]
    }
    
    private func setPlayerItemThumbnailMetadata() async {
        let thumbnailPlaceholderItem = makePlayerItemThumbnailPlaceholder()
        playerItem.externalMetadata.append(thumbnailPlaceholderItem)
        
        let thumbnailItem = AVMutableMetadataItem()
        thumbnailItem.identifier = .commonIdentifierArtwork
        
        guard let imageData = await getThumbnailMetadataItem(node: node)?.pngData() else { return }
        thumbnailItem.value = imageData as any (NSCopying & NSObjectProtocol)
        thumbnailItem.dataType = node.mnz_fileType()
        
        playerItem.externalMetadata.remove(object: thumbnailPlaceholderItem)
        playerItem.externalMetadata.append(thumbnailItem)
    }
    
    private func makePlayerItemThumbnailPlaceholder() -> AVMutableMetadataItem {
        let thumbnailItem = AVMutableMetadataItem()
        thumbnailItem.identifier = .commonIdentifierArtwork
        
        guard let placeholderImageData = nodeAssetManager.icon(for: node).pngData() else { return thumbnailItem }
        thumbnailItem.value = placeholderImageData as any (NSCopying & NSObjectProtocol)
        thumbnailItem.dataType = node.mnz_fileType()
        
        return thumbnailItem
    }
    
    private func getThumbnailMetadataItem(node: MEGANode) async -> UIImage? {
        await withAsyncValue { @Sendable result in
            guard node.hasThumbnail() else {
                result(.success(nodeAssetManager.icon(for: node)))
                return
            }
            
            let thumbnailFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "thumbnailsV3")
            
            guard fileManager.fileExists(atPath: thumbnailFilePath) else {
                let getThumbnailRequestDelegate = RequestDelegate { requestResult in
                    switch requestResult {
                    case .success(let request):
                        guard request.nodeHandle == node.handle, let file = request.file else { return result(.success(nodeAssetManager.icon(for: node))) }
                        result(.success(UIImage(contentsOfFile: file)))
                    case .failure:
                        result(.success(nodeAssetManager.icon(for: node)))
                    }
                }
                sdk.getThumbnailNode(node, destinationFilePath: thumbnailFilePath, delegate: getThumbnailRequestDelegate)
                return
            }
            
            result(.success(UIImage(contentsOfFile: thumbnailFilePath)))
        }
    }
}
