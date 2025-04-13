import Combine
import Foundation
import MEGADomain
import MEGASwift

@MainActor
protocol SlideShowDataSourceProtocol {
    var items: [Int: SlideShowCellViewModel] { get }
    var count: Int { get }
    func download(fromCurrentIndex index: Int)
    func loadSelectedPhotoPreview(completionHandler: (() -> Void)?)
    func sortNodes(byOrder order: SlideShowPlayingOrderEntity)
    func indexOfCurrentPhoto() -> Int
}

final class SlideShowDataSource: SlideShowDataSourceProtocol {
    var items: [Int: SlideShowCellViewModel] = [:]
    var count: Int { nodeEntities.count }

    private var nodeEntities: [NodeEntity]
    private var currentPhoto: NodeEntity?
    private let loader: MediaEntityLoader
    private let advanceNumberOfPhotosToLoad: Int
    private var loadSelectionPhotoSubscription: AnyCancellable?

    init(
        currentPhoto: NodeEntity?,
        nodeEntities: [NodeEntity],
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        fileDownloadUseCase: some FileDownloadUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        advanceNumberOfPhotosToLoad: Int
    ) {
        self.currentPhoto = currentPhoto
        self.nodeEntities = nodeEntities
        self.advanceNumberOfPhotosToLoad = advanceNumberOfPhotosToLoad
        self.loader = MediaEntityLoader(
            thumbnailUseCase: thumbnailUseCase,
            fileDownloadUseCase: fileDownloadUseCase,
            mediaUseCase: mediaUseCase)
    }
    
    func indexOfCurrentPhoto() -> Int {
        guard let currentPhoto else {
            return 0
        }
        return nodeEntities.firstIndex(of: currentPhoto) ?? 0
    }

    func loadSelectedPhotoPreview(completionHandler: (() -> Void)?) {
        guard let node = currentPhoto else {
            return
        }

        let cellVM = cellViewModel(for: node)
        loadSelectionPhotoSubscription = cellVM.$imageSource
            .filter { $0 != nil }
            .sink { [weak self] _ in
                guard let self else { return }
                loadSelectionPhotoSubscription?.cancel()
                loadSelectionPhotoSubscription = nil
                completionHandler?()
            }

        items[indexOfCurrentPhoto()] = cellVM
    }

    private func cellViewModel(for node: NodeEntity) -> SlideShowCellViewModel {
        .init(node: node, loader: loader)
    }
    
    func download(fromCurrentIndex index: Int) {
        
        let validIndex = (index >= nodeEntities.count || index < 0) ? 0 : index
        
        // Update current photo
        currentPhoto = nodeEntities[safe: validIndex]
        
        let minRange = max(0, validIndex - advanceNumberOfPhotosToLoad)
        let expectedMaxRange = validIndex + advanceNumberOfPhotosToLoad
        let maxRange = min(nodeEntities.count - 1, expectedMaxRange)
        
        let range = Array(minRange...maxRange)
        
        // Determine if assets need to load from the beginning of list, in overflow range
        let overFlowRange = if expectedMaxRange > nodeEntities.count {
            Array(0..<min(expectedMaxRange - nodeEntities.count + 1, minRange))
        } else {
            Array(0..<0) // AKA: Empty range
        }
            
        // Clear Cached VM that are outside our range of required pre-caching
        let minIndexRangeToKeep = max(minRange, overFlowRange.min() ?? 0)
        items = items.filter { $0.key < minIndexRangeToKeep || $0.key > maxRange }
        
        // Create Item or skip if item already exists
        for photoPosition in [range, overFlowRange].joined() {
            
            guard items[photoPosition] == nil,
                  let node = nodeEntities[safe: photoPosition] else {
                continue
            }

            items[photoPosition] = cellViewModel(for: node)
        }
    }
        
    func sortNodes(byOrder order: SlideShowPlayingOrderEntity) {
        if order == .newest {
            nodeEntities.sort { $0.modificationTime > $1.modificationTime }
        } else if order == .oldest {
            nodeEntities.sort { $0.modificationTime < $1.modificationTime }
        } else {
            nodeEntities.shuffle()
        }
        
        resetDataIfRequired(basedOn: order)
    }
    
    private func resetDataIfRequired(basedOn order: SlideShowPlayingOrderEntity) {
        switch order {
        case .newest, .oldest:
            break
        case .shuffled:
            items.removeAll()
        }
    }
}
