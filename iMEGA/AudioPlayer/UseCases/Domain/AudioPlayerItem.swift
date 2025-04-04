@preconcurrency import AVFoundation
import Foundation
import MEGAAppSDKRepo
import MEGAL10n

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
        NodeThumbnailHomeUseCase(
            sdkNodeClient: .live,
            fileSystemClient: .live,
            thumbnailRepo: ThumbnailRepository.newRepo
        )
    }()
    
    var nameUpdatedByMetadata: Bool {
        loadedMetadata && name != node?.name
    }
    
    init(name: String, url: URL, node: MEGANode?, hasThumbnail: Bool = false) {
        self.name = node?.name ?? name
        self.url = url
        self.node = node
        self.nodeHasThumbnail = hasThumbnail
        
        super.init(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: requiredAssetKeys)
    }
    
    func loadMetadata() async throws {
        try Task.checkCancellation()
        
        let metadataItems = try await asset.load(.commonMetadata)
        
        try Task.checkCancellation()
        
        let title = metadataItems.first(where: { $0.commonKey == .commonKeyTitle })?.value as? String
        
        if let title {
            self.name = title
        }
        
        self.artist = if let artist = metadataItems.first(where: { $0.commonKey == .commonKeyArtist })?.value as? String {
            artist
        } else if title != nil { // Only show unknown artist if the title can be determined
            Strings.Localizable.Media.Audio.Metadata.Missing.artist
        } else {
            nil
        }
        
        if let albumName = metadataItems.first(where: { $0.commonKey == .commonKeyAlbumName })?.value as? String {
            self.album = albumName
        }
        
        if let artworkData = metadataItems.first(where: { $0.commonKey == .commonKeyArtwork })?.value as? Data, let artworkImage = UIImage(data: artworkData) {
            self.artwork = artworkImage
        } else if nodeHasThumbnail {
            self.artwork = await loadThumbnail()
        }
        
        loadedMetadata = true
    }
    
    private func loadThumbnail() async -> UIImage? {
        guard let node else { return nil }
        return await nodeThumbnailHomeUseCase.loadThumbnail(of: node.handle)
    }
}
