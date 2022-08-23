import MEGADomain
import MEGASwiftUI

enum SlideShowAction: ActionType {
    case startPlaying
    case pausePlaying
    case playOrPause
    case finishPlaying
}

final class SlideShowViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case startPlaying
        case pausePlaying
    }
    
    static let SlideShowAutoPlayingTimeInSeconds: Double = 4
    
    var invokeCommand: ((Command) -> Void)?
    
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    private let dataProvider: PhotoBrowserDataProvider
    
    var playbackStatus: SlideshowPlaybackStatus = .initialized
    var photos = [SlideShowMediaEntity]()
    var numberOfSlideShowImages = 0
    
    init(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        dataProvider: PhotoBrowserDataProvider
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.dataProvider = dataProvider
        
        numberOfSlideShowImages =  dataProvider.allPhotoEntities.lazy.filter{ $0.isImage }.count
        
        Task {
            await loadAllPhotoPreviews()
        }
    }
    
    private func loadAllPhotoPreviews() async {
        guard dataProvider.allPhotoEntities.isNotEmpty else { return }
        
        for node in dataProvider.allPhotoEntities.lazy.filter({ $0.isImage }) {
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
        }
    }
}
