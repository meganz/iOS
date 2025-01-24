import Foundation
import MEGAL10n
import MEGASDKRepo

final class AudioPlayerItem: AVPlayerItem {
    var name: String
    var url: URL
    var artist: String?
    var album: String?
    var nodeHasThumbnail: Bool
    var artwork: UIImage?
    var node: MEGANode?
    var loadedMetadata = false
    
    let requiredAssetKeys = [
            "playable",
            "hasProtectedContent"
        ]
    
    private lazy var nodeThumbnailHomeUseCase: some NodeThumbnailHomeUseCaseProtocol = {
        return NodeThumbnailHomeUseCase(sdkNodeClient: .live,
                                        fileSystemClient: .live,
                                        thumbnailRepo: ThumbnailRepository.newRepo)
    }()
    
    init(name: String, url: URL, node: MEGANode?, hasThumbnail: Bool = false) {
        self.name = node?.name ?? name
        self.url = url
        self.node = node
        self.nodeHasThumbnail = hasThumbnail
        
        super.init(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: requiredAssetKeys)
    }
    
    func loadMetadata(completion: @escaping () -> Void) {
        asset.loadMetadata { [weak self] title, artist, albumName, artworkData in
            guard let self else { return }
            
            name = if let title {
                title
            } else {
                node?.name ?? ""
            }
            
            self.artist = if let artist {
                artist
            } else if title != nil { // Only show unknown artist if the title can be determined
                Strings.Localizable.Media.Audio.Metadata.Missing.artist
            } else {
                nil
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
