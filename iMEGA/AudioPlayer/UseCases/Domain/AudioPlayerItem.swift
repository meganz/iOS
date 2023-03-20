import Foundation

final class AudioPlayerItem: AVPlayerItem {
    var name: String
    var url: URL
    var title: String?
    var artist: String?
    var album: String?
    var nodeHasThumbnail: Bool
    var artwork: UIImage?
    var node: MEGANode?
    var loadedMetadata = false
    var startTimeStamp: Double?
    
    let requiredAssetKeys = [
            "playable",
            "hasProtectedContent"
        ]
    
    private lazy var nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol = {
        return NodeThumbnailHomeUseCase(sdkNodeClient: .live,
                                        fileSystemClient: .live,
                                        thumbnailRepo: ThumbnailRepository.newRepo)
    }()
    
    init(name: String, url: URL, node: MEGANode?, hasThumbnail: Bool = false) {
        self.name = name
        self.url = url
        self.node = node
        self.nodeHasThumbnail = hasThumbnail
        
        super.init(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: requiredAssetKeys)
    }
    
    func loadMetadata(completion: @escaping () -> Void) {
        asset.loadMetadata { [weak self] title, artist, albumName, artworkData in
            guard let `self` = self else { return }
            if let title = title {
                self.name = title
                self.title = title
            }
            
            if let artist = artist {
                self.artist = artist
            }
            
            if let albumName = albumName {
                self.album = albumName
            }
            
            if let artworkData = artworkData, let artworkImage = UIImage(data: artworkData) {
                self.artwork = artworkImage
            } else if self.nodeHasThumbnail {
                self.loadThumbnail()
            }
            
            self.loadedMetadata = true
            
            completion()
        }
    }
    
    func loadThumbnail(completionBlock: ((UIImage?, UInt64) -> Void)? = nil) {
        guard let node = node else { return }
        if let artworkImage = artwork {
            completionBlock?(artworkImage, node.handle)
        } else {
            nodeThumbnailHomeUseCase.loadThumbnail(of: node.handle) { [weak self] in
                self?.artwork = $0
                completionBlock?($0, node.handle)
            }
        }
    }
}

extension AudioPlayerItem {
    static func == (lhs: AudioPlayerItem, rhs: AudioPlayerItem) -> Bool {
        guard let lhsNode = lhs.node?.handle, let rhsNode = rhs.node?.handle else {
            return lhs.url == rhs.url
        }
        return lhsNode == rhsNode
    }
}
