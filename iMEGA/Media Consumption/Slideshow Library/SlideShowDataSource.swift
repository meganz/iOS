import Foundation
import MEGADomain

protocol SlideShowDataSourceProtocol {
    var photos: [SlideShowMediaEntity] { get set }
    var nodeEntities: [NodeEntity] { get set }
    var initialPhotoDownloadCallback: (() -> ())? { get set }
    
    func resetData()
    func loadSelectedPhotoPreview() -> Bool
    func startInitialDownload(_ initialPhotoDownloaded: Bool)
    func processData(basedOnCurrentSlideNumber currentSlideNumber: Int, andOldSlideNumber oldSlideNumber: Int)
    func sortNodes(byOrder order: SlideShowPlayingOrderEntity)
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
    var initialPhotoDownloadCallback: (() -> ())?
    private let fileExistenceUseCase: FileExistUseCaseProtocol
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let mediaUseCase: MediaUseCase
    private let advanceNumberOfPhotosToLoad: Int
    private let numberOfUnusedPhotosBuffer: Int
    private var sortByShuffleOrder = false
    
    private var isResetData = false
    private var isBatchDownloadInProgress = false {
        willSet {
            if newValue == false && isResetData {
                isResetData = false
                restartDownload()
            }
        }
    }
    
    init(
        currentPhoto: NodeEntity?,
        nodeEntities: [NodeEntity],
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        mediaUseCase: MediaUseCase,
        fileExistenceUseCase: FileExistUseCaseProtocol,
        advanceNumberOfPhotosToLoad: Int,
        numberOfUnusedPhotosBuffer: Int
    ) {
        self.currentPhoto = currentPhoto
        self.nodeEntities = nodeEntities
        self.thumbnailUseCase = thumbnailUseCase
        self.mediaUseCase = mediaUseCase
        self.advanceNumberOfPhotosToLoad = advanceNumberOfPhotosToLoad
        self.numberOfUnusedPhotosBuffer = numberOfUnusedPhotosBuffer
        self.fileExistenceUseCase = fileExistenceUseCase
    }
    
    func loadSelectedPhotoPreview() -> Bool {
        guard let node = currentPhoto,
              let pathForPreviewOrOriginal = thumbnailUseCase.cachedPreviewOrOriginalPath(for: node)
        else {
            return false
        }
        
        if let entity = slideShowMediaEntity(for: node, with: mediaUseCase.isGifImage(node.name) ? thumbnailUseCase.generateCachingURL(for: node, type: .original).path : pathForPreviewOrOriginal) {
            photos.append(entity)
        }
        return true
    }
    
    func startInitialDownload(_ initialPhotoDownloaded: Bool) {
        let num = initialPhotoDownloaded ? advanceNumberOfPhotosToLoad - 1 : advanceNumberOfPhotosToLoad
        loadNextSetOfPhotosPreview(num, withInitialPhoto: !initialPhotoDownloaded)
    }
    
    func resetData() {
        thumbnailLoadingTask?.cancel()
        
        if !isBatchDownloadInProgress {
            restartDownload()
        } else {
            isResetData = true
        }
    }
    
    func processData(basedOnCurrentSlideNumber currentSlideNumber: Int, andOldSlideNumber oldSlideNumber: Int) {
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
    
    func sortNodes(byOrder order: SlideShowPlayingOrderEntity) {
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
    
    private func restartDownload() {
        photos.removeAll()
        startInitialDownload(false)
    }
    
    private func shouldLoadMorePhotos(_ currentSlideNumber: Int) -> Bool {
        photos.count - currentSlideNumber < advanceNumberOfPhotosToLoad &&
        photos.count < nodeEntities.count
    }
    
    private func selectNextSetOfPhotos(_ num: Int, withInitialPhoto initialPhoto: Bool) -> [NodeEntity] {
        let startPhotoNum = photos.count == 1 && photos.count < nodeEntities.count ? 0 : photos.count
        let diff = nodeEntities.count - photos.count
        let numOfPhotos = diff > num ? num : diff
        
        var nextPhotoSet = [NodeEntity]()
        var counter = 0
        
        for i in startPhotoNum..<nodeEntities.count {
            let node = nodeEntities[i]
            
            if !initialPhoto, let currentPhoto = currentPhoto, currentPhoto.handle == node.handle { continue }
            counter += 1
            nextPhotoSet.append(node)
            if counter >= numOfPhotos { break }
        }
        
        return nextPhotoSet
    }
    
    private func loadNextSetOfPhotosPreview(_ num: Int, withInitialPhoto initialPhoto: Bool) {
        guard nodeEntities.count > 0 else { return }
        guard photos.count < nodeEntities.count else { return }
        guard thumbnailLoadingTask?.isCancelled ?? true else { return }
        
        thumbnailLoadingTask = Task {
            isBatchDownloadInProgress = true
            var nextSetOfPhotos = selectNextSetOfPhotos(num, withInitialPhoto: initialPhoto)
            
            if sortByShuffleOrder {
                nextSetOfPhotos.shuffle()
            }
            
            for node in nextSetOfPhotos {
                if isResetData { break }
                if let mediaEntity = await loadMediaEntity(forNode: node) {
                    if isResetData { break }
                    photos.append(mediaEntity)
                }
            }
            
            thumbnailLoadingTask = nil
            isBatchDownloadInProgress = false
        }
    }
    
    private func loadMediaEntity(forNode node: NodeEntity) async -> SlideShowMediaEntity? {
        async let photo = try? thumbnailUseCase.loadThumbnail(for: node, type: mediaUseCase.isGifImage(node.name) ? .original : .preview)
        if let photoPath = await photo?.path {
            return slideShowMediaEntity(for: node, with: photoPath)
        }
        return nil
    }
    
    private func slideShowMediaEntity(for node: NodeEntity, with filePath: String) -> SlideShowMediaEntity? {
        if mediaUseCase.isGifImage(node.name),
            let url = getFileUrl(for: node, having: filePath),
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data) {
            return SlideShowMediaEntity(image: image, node: node, fileUrl: url)
        }
        if let image = UIImage(contentsOfFile: filePath) {
            return SlideShowMediaEntity(image: image, node: node, fileUrl: nil)
        }
        return nil
    }
    
    func getFileUrl(for node: NodeEntity, having path: String) -> URL? {
        let fileUrl = URL(fileURLWithPath: path.append(pathComponent: node.name))
        if fileExistenceUseCase.fileExists(at: fileUrl) {
            return fileUrl
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
        if photos.indices.contains(unusedPhotoIdx) {
            photos[unusedPhotoIdx].image = nil
        }
    }
}
