@preconcurrency import AVFoundation
import Foundation

enum MetadataLoadError: Error {
    case cancelled
}

extension AudioPlayer: AudioPlayerMetadataLoaderProtocol {

    func preloadNextTracksMetadata() {
        tracks.compactMap { $0.loadedMetadata ? nil: $0 }
            .prefix(preloadMetadataMaxItems)
            .compactMap(createOperation)
            .forEach(opQueue.addOperation)
    }
    
    func createOperation(with item: AudioPlayerItem) -> AudioPlayerMetadataOperation {
        AudioPlayerMetadataOperation(item: item, completion: { result in
            switch result {
            case .failure(let error):
                MEGALogError("[AudioPlayer] Metadata Loader error: \(error.localizedDescription)")
            case .success:
                if self.queuePlayer?.currentItem == item { self.notify([self.aboutCurrentItem, self.aboutCurrentThumbnail, self.aboutToReloadCurrentItem]) }
                self.notifyAboutToReload(item: item)
            }
        })
    }
    
    @MainActor
    func loadACurrentItemArtworkIfNeeded() async {
        guard let currentItem = currentItem(), currentItem.artwork == nil else { return }
        let asset = currentItem.asset
        
        guard let metadata = try? await asset.load(.commonMetadata) else { return }
        let artworkMetadata = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork)
        
        guard
            let firstArtwork = artworkMetadata.first,
            let imageData = firstArtwork.dataValue,
            let image = UIImage(data: imageData) else {
            return
        }
        
        self.currentItem()?.artwork = image
    }
}

final class AudioPlayerMetadataOperation: MEGAOperation, @unchecked Sendable {
    private let item: AudioPlayerItem
    private let completion: (Result<Void, any Error>) -> Void
    
    init(item: AudioPlayerItem, completion: @escaping (Result<Void, any Error>) -> Void) {
        self.item = item
        self.completion = completion
    }
    
    override func start() {
        guard !isCancelled else {
            finishOperation(error: MetadataLoadError.cancelled)
            return
        }
        startExecuting()
        loadItemMetadata()
    }
    
    private func finishOperation(error: (any Error)?) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
        finish()
    }
    
    private func loadItemMetadata() {
        item.loadMetadata { [weak self] in
            self?.finishOperation(error: nil)
        }
    }
}
