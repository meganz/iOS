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
    
    static let SlideShowAutoPlayingTimeInSeconds: Double = 4
    
    var invokeCommand: ((Command) -> Void)?
    
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    private let dataProvider: PhotoBrowserDataProvider
    
    var playbackStatus: SlideshowPlaybackStatus = .initialized
    var photos = [SlideShowMediaEntity]()
    var numberOfSlideShowImages = 0
    
    var currentSlideNumber = 0
    
    private let mediaUseCase: MediaUseCaseProtocol
    
    init(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        dataProvider: PhotoBrowserDataProvider,
        mediaUseCase: MediaUseCaseProtocol = MediaUseCase()
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.dataProvider = dataProvider
        self.mediaUseCase = mediaUseCase
        
        numberOfSlideShowImages = dataProvider.allPhotoEntities.lazy.filter{ mediaUseCase.isImage(for: URL(fileURLWithPath: $0.name)) }.count
        
        Task {
            await loadSelectedPhotoPreview()
            await loadAllPhotoPreviews()
        }
    }
    
    private func loadSelectedPhotoPreview() async {
        guard let node = dataProvider.currentPhoto else { return }
        
        if let pathForPreviewOrOriginal = thumbnailUseCase.cachedPreviewOrOriginalPath(for: node.toNodeEntity()),
           let image = UIImage(contentsOfFile: pathForPreviewOrOriginal) {
            self.photos.append(SlideShowMediaEntity(image: image))
            invokeCommand?(.initialPhotoLoaded)
            return
        }
        
        guard let photo = try? await thumbnailUseCase.loadThumbnail(for: node.toNodeEntity(), type: .preview) else { return }
        if let image = UIImage(contentsOfFile: photo.path) {
            self.photos.append(SlideShowMediaEntity(image: image))
            invokeCommand?(.initialPhotoLoaded)
        }
    }
    
    private func loadAllPhotoPreviews() async {
        guard dataProvider.allPhotoEntities.isNotEmpty else { return }
        
        for node in dataProvider.allPhotoEntities.shuffled().lazy.filter({ self.mediaUseCase.isImage(for: URL(fileURLWithPath: $0.name)) }) {
            if let currentPhoto = dataProvider.currentPhoto, currentPhoto.handle == node.handle { continue }
            if playbackStatus == .complete { break }
            
            guard let photo = try? await thumbnailUseCase.loadThumbnail(for: node, type: .preview) else { return }
            if let image = UIImage(contentsOfFile: photo.path) {
                self.photos.append(SlideShowMediaEntity(image: image))
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
