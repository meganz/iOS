import Foundation
import MEGADomain

protocol SlideShowDataSourceProtocol {
    var photos: [SlideShowMediaEntity] { get set }
    var nodeEntities: [NodeEntity] { get set }
    var slideshowComplete: Bool { get set }
    var initialPhotoDownloadCallback: (() -> ())? { get set }
    
    func loadSelectedPhotoPreview() -> Bool
    func startInitialDownload(_ initialPhotoDownloaded: Bool)
    func processData(basedOnCurrentSlideNumber currentSlideNumber: Int, andOldSlideNumber oldSlideNumber: Int)
    func sortNodes(byOrder order: SlideShowPlayingOrder)
}

final class SlideShowDataSource: SlideShowDataSourceProtocol {
    var nodeEntities: [NodeEntity]
    var currentPhoto: NodeEntity?
    
    var photos = [SlideShowMediaEntity]() {
        didSet {
            if photos.count == 1 {
                initialPhotoDownloadCallback?()
            }
        }
    }
    var thumbnailLoadingTask: Task<Void, Never>?
    var slideshowComplete: Bool = false
    
    var initialPhotoDownloadCallback: (() -> ())?
    
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let advanceNumberOfPhotosToLoad: Int
    private let numberOfUnusedPhotosBuffer: Int

    private var numberOfNodeProcessed = 0
    private var sortByShuffleOrder = false
    
    init(
        currentPhoto: NodeEntity?,
        nodeEntities: [NodeEntity],
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        mediaUseCase: MediaUseCaseProtocol,
        advanceNumberOfPhotosToLoad: Int,
        numberOfUnusedPhotosBuffer: Int
    ) {
        self.currentPhoto = currentPhoto
        self.nodeEntities = nodeEntities
        self.thumbnailUseCase = thumbnailUseCase
        self.mediaUseCase = mediaUseCase
        self.advanceNumberOfPhotosToLoad = advanceNumberOfPhotosToLoad
        self.numberOfUnusedPhotosBuffer = numberOfUnusedPhotosBuffer
    }
    
    func loadSelectedPhotoPreview() -> Bool {
        guard let node = currentPhoto,
              let pathForPreviewOrOriginal = thumbnailUseCase.cachedPreviewOrOriginalPath(for: node)
        else {
            return false
        }
        
        numberOfNodeProcessed += 1
        if let image = UIImage(contentsOfFile: pathForPreviewOrOriginal) {
            photos.append(SlideShowMediaEntity(image: image, node: node))
        }

        return true
    }
    
    func startInitialDownload(_ initialPhotoDownloaded: Bool) {
        slideshowComplete = false
        let num = initialPhotoDownloaded ? advanceNumberOfPhotosToLoad - 1 : advanceNumberOfPhotosToLoad
        loadNextSetOfPhotosPreview(num, withInitialPhoto: !initialPhotoDownloaded)
    }
    
    func processData(basedOnCurrentSlideNumber currentSlideNumber: Int, andOldSlideNumber oldSlideNumber: Int) {
        guard !isInitialDownload(currentSlideNumber) else { return }
    
        if shouldLoadMorePhotos(currentSlideNumber) {
            loadNextSetOfPhotosPreview(advanceNumberOfPhotosToLoad, withInitialPhoto: false)
        }
        
        if oldSlideNumber > currentSlideNumber {
            reloadUnusedPhotos(currentSlideNumber)
        }
        else if currentSlideNumber > oldSlideNumber {
            removeUnusedPhotos(currentSlideNumber)
        }
    }
    
    func sortNodes(byOrder order: SlideShowPlayingOrder) {
        sortByShuffleOrder = false
        if order == .newest {
            nodeEntities.sort { $0.modificationTime > $1.modificationTime }
        } else if order == .oldest {
            nodeEntities.sort { $0.modificationTime < $1.modificationTime }
        } else {
            sortByShuffleOrder = true
        }
    }
    
    // MARK: - Private
    
    private func isInitialDownload(_ currentSlideNumber: Int) -> Bool {
        currentSlideNumber < 10 && photos.count <= advanceNumberOfPhotosToLoad
    }
    
    private func shouldLoadMorePhotos(_ currentSlideNumber: Int) -> Bool {
        photos.count - currentSlideNumber < advanceNumberOfPhotosToLoad &&
        numberOfNodeProcessed < nodeEntities.count
    }
    
    private func selectNextSetOfPhotos(_ num: Int, withInitialPhoto initialPhoto: Bool) -> [NodeEntity] {
        let startPhotoNum = photos.count == 1 && photos.count < nodeEntities.count ? 0 : photos.count
        let diff = nodeEntities.count - photos.count
        let numOfPhotos = diff > num ? num : diff
        
        var nextPhotoSet = [NodeEntity]()
        var counter = 0
        
        for i in startPhotoNum..<nodeEntities.count {
            numberOfNodeProcessed = i
            let node = nodeEntities[i]
            
            if !initialPhoto, let currentPhoto = currentPhoto, currentPhoto.handle == node.handle { continue }
            
            if mediaUseCase.isImage(for: URL(fileURLWithPath: node.name)) {
                counter += 1
                nextPhotoSet.append(node)
            }
            if counter >= numOfPhotos { break }
        }
        
        return nextPhotoSet
    }
    
    private func loadNextSetOfPhotosPreview(_ num: Int, withInitialPhoto initialPhoto: Bool) {
        guard nodeEntities.count > 0 else { return }
        guard photos.count < nodeEntities.count else { return }
        
        thumbnailLoadingTask = Task {
            var nextSetOfPhotos = selectNextSetOfPhotos(num, withInitialPhoto: initialPhoto)
            
            if sortByShuffleOrder {
                nextSetOfPhotos.shuffle()
            }
            
            for node in nextSetOfPhotos {
                if slideshowComplete { break }
                
                if let mediaEntity = await loadMediaEntity(forNode: node) {
                    photos.append(mediaEntity)
                }
            }
        }
    }
    
    private func loadMediaEntity(forNode node: NodeEntity) async -> SlideShowMediaEntity? {
        async let photo = try? thumbnailUseCase.loadThumbnail(for: node, type: .preview)
        if let photoPath = await photo?.path, let image = UIImage(contentsOfFile: photoPath) {
            return SlideShowMediaEntity(image: image, node: node)
        }
        
        return nil
    }
    
    private func reloadUnusedPhotos(_ currentSlideNumber: Int) {
        let reloadIdx = currentSlideNumber - numberOfUnusedPhotosBuffer + 1
        guard reloadIdx >= 0 && photos[reloadIdx].image == nil else { return }
        
        thumbnailLoadingTask = Task {
            if let mediaEntity = await loadMediaEntity(forNode: photos[reloadIdx].node) {
                photos[reloadIdx].image = mediaEntity.image
            }
        }
    }
    
    private func removeUnusedPhotos(_ currentSlideNumber: Int) {
        guard currentSlideNumber >= numberOfUnusedPhotosBuffer else { return }
        
        let unusedPhotoIdx = currentSlideNumber - numberOfUnusedPhotosBuffer
        if unusedPhotoIdx >= 0 {
            photos[unusedPhotoIdx].image = nil
        }
    }
}
