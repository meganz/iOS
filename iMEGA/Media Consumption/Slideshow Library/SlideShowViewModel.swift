import MEGADomain
import MEGASwiftUI
import Foundation

enum SlideShowAction: ActionType {
    case startPlaying
    case pausePlaying
    case playOrPause
    case finishPlaying
    case resetTimer
}

final class SlideShowViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case startPlaying
        case pausePlaying
        case initialPhotoLoaded
        case resetTimer
    }
    
    private let advanceNumberOfPhotosToLoad = 20
    private let numberOfUnusedPhotosBuffer = 20
    
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let dataProvider: PhotoBrowserDataProviderProtocol
    private let configuration: SlideShowViewConfiguration
    
    var thumbnailLoadingTask: Task<Void, Never>?
    
    var invokeCommand: ((Command) -> Void)?
    
    var playbackStatus: SlideshowPlaybackStatus = .initialized
    var photos = [SlideShowMediaEntity]()
    
    var numberOfNodeProcessed = 0
    var numberOfSlideShowContents: Int {
        dataProvider.allPhotoEntities.count
    }
    
    var timeIntervalForSlideInSeconds: Double {
        configuration.timeIntervalForSlideInSeconds
    }
    
    private var shouldLoadMorePhotos: Bool {
        photos.count - currentSlideNumber < advanceNumberOfPhotosToLoad &&
        numberOfNodeProcessed < numberOfSlideShowContents
    }
    
    var isInitialDownload: Bool {
        currentSlideNumber < 10 && photos.count <= advanceNumberOfPhotosToLoad
    }
    
    var currentSlideNumber = 0 {
        didSet {
            guard !isInitialDownload else { return }
        
            if shouldLoadMorePhotos {
                loadNextSetOfPhotosPreview(advanceNumberOfPhotosToLoad)
            }
            
            if oldValue > currentSlideNumber {
                reloadUnusedPhotos()
            }
            else if currentSlideNumber > oldValue {
                removeUnusedPhotos()
            }
        }
    }
    
    init(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        dataProvider: PhotoBrowserDataProviderProtocol,
        mediaUseCase: MediaUseCaseProtocol,
        configuration: SlideShowViewConfiguration
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.dataProvider = dataProvider
        self.mediaUseCase = mediaUseCase
        self.configuration = configuration
        
        startInitialDownload()
    }
    
    private func startInitialDownload() {
        loadSelectedPhotoPreview()
        loadNextSetOfPhotosPreview(advanceNumberOfPhotosToLoad - 1)
    }
    
    private func loadSelectedPhotoPreview() {
        guard let node = dataProvider.currentPhoto?.toNodeEntity() else { return }
        numberOfNodeProcessed += 1
        
        if let pathForPreviewOrOriginal = thumbnailUseCase.cachedPreviewOrOriginalPath(for: node),
           let image = UIImage(contentsOfFile: pathForPreviewOrOriginal) {
            self.photos.append(SlideShowMediaEntity(image: image, node: node))
            invokeCommand?(.initialPhotoLoaded)
        }
        else {
            thumbnailLoadingTask = Task (priority: .userInitiated) {
                if let mediaEntity = await loadMediaEntity(forNode: node) {
                    self.photos.append(mediaEntity)
                    invokeCommand?(.initialPhotoLoaded)
                }
            }
        }
    }
    
    private func selectNextSetOfPhotos(_ num: Int) -> [NodeEntity] {
        let startPhotoNum = photos.count == 1 && photos.count < numberOfSlideShowContents ? 0 : photos.count
        let diff = numberOfSlideShowContents - photos.count
        let numOfPhotos = diff > num ? num : diff
        
        var nextPhotoSet = [NodeEntity]()
        var counter = 0
        
        for i in startPhotoNum..<numberOfSlideShowContents {
            numberOfNodeProcessed = i
            let node = dataProvider.allPhotoEntities[i]
            if let currentPhoto = dataProvider.currentPhoto, currentPhoto.handle == node.handle { continue }
            
            if self.mediaUseCase.isImage(for: URL(fileURLWithPath: node.name)) {
                counter += 1
                nextPhotoSet.append(node)
            }
            if counter >= numOfPhotos { break }
        }
        
        return nextPhotoSet
    }
    
    private func loadMediaEntity(forNode node: NodeEntity) async -> SlideShowMediaEntity? {
        async let photo = try? thumbnailUseCase.loadThumbnail(for: node, type: .preview)
        if let photoPath = await photo?.path, let image = UIImage(contentsOfFile: photoPath) {
            return SlideShowMediaEntity(image: image, node: node)
        }
        
        return nil
    }
    
    private func loadNextSetOfPhotosPreview(_ num: Int) {
        guard numberOfSlideShowContents > 0 else { return }
        guard photos.count < numberOfSlideShowContents else { return }
        
        thumbnailLoadingTask = Task {
            var nextSetOfPhotos = selectNextSetOfPhotos(num)
            if configuration.playingOrder == .shuffled {
                nextSetOfPhotos = nextSetOfPhotos.shuffled()
            }
            
            for node in nextSetOfPhotos.lazy {
                if playbackStatus == .complete { break }
                
                if let mediaEntity = await loadMediaEntity(forNode: node) {
                    self.photos.append(mediaEntity)
                }
            }
        }
    }
    
    private func removeUnusedPhotos() {
        guard currentSlideNumber >= numberOfUnusedPhotosBuffer else { return }
        
        let unusedPhotoIdx = currentSlideNumber - numberOfUnusedPhotosBuffer
        if unusedPhotoIdx >= 0 {
            photos[unusedPhotoIdx].image = nil
        }
    }
    
    private func reloadUnusedPhotos() {
        let reloadIdx = currentSlideNumber - numberOfUnusedPhotosBuffer + 1
        guard reloadIdx >= 0 && photos[reloadIdx].image == nil else { return }
        
        thumbnailLoadingTask = Task {
            if let mediaEntity = await loadMediaEntity(forNode: photos[reloadIdx].node) {
                photos[reloadIdx].image = mediaEntity.image
            }
        }
    }
    
    private func playOrPauseSlideShow() {
        guard playbackStatus == .playing
        else {
            playbackStatus = .playing
            invokeCommand?(.startPlaying)
            return
        }
        
        playbackStatus = .pause
        invokeCommand?(.pausePlaying)
    }
    
    func dispatch(_ action: SlideShowAction) {
        switch action {
        case .startPlaying:
            playbackStatus = .playing
            invokeCommand?(.startPlaying)
        case .pausePlaying:
            playbackStatus = .pause
            invokeCommand?(.pausePlaying)
        case .playOrPause:
            playOrPauseSlideShow()
        case .finishPlaying:
            playbackStatus = .complete
            invokeCommand?(.pausePlaying)
        case .resetTimer:
            invokeCommand?(.resetTimer)
        }
    }
}
