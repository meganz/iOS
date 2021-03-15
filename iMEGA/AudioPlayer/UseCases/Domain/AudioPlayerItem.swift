import Foundation

final class AudioPlayerItem: AVPlayerItem {
    var name: String
    var url: URL
    var artist: String?
    var album: String?
    var nodeHasThumbnail: Bool
    var artwork: UIImage?
    var node: MEGAHandle?
    var loadedMetadata = false
    
    let requiredAssetKeys = [
            "playable",
            "hasProtectedContent"
        ]
    
    private lazy var nodeThumbnailUseCase: NodeThumbnailUseCaseProtocol = {
        return NodeThumbnailUseCase(sdkNodeClient: .live,
                                    fileSystemClient: .live,
                                    filePathUseCase: MEGAAppGroupFilePathUseCase())
    }()
    
    init(name: String, url: URL, node: MEGAHandle?, hasThumbnail: Bool = false) {
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
        guard let nodeHandle = node else { return }
        if let artworkImage = artwork {
            completionBlock?(artworkImage, nodeHandle)
        } else {
            nodeThumbnailUseCase.loadThumbnail(of: nodeHandle) { [weak self] in
                self?.artwork = $0
                completionBlock?($0, nodeHandle)
            }
        }
    }
}

extension AudioPlayerItem {
    static func == (lhs: AudioPlayerItem, rhs: AudioPlayerItem) -> Bool {
        guard let lhsNode = lhs.node, let rhsNode = rhs.node else {
            return lhs.url == rhs.url
        }
        return lhsNode == rhsNode
    }
}
