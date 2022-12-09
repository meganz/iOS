import MEGADomain
import MEGASwiftUI
import Foundation

enum SlideShowAction: ActionType {
    case play
    case pause
    case finish
    case resetTimer
}

protocol SlideShowViewModelPreferenceProtocol {
    func pause()
    func cancel()
    func restart(withConfig config: SlideShowConfigurationEntity)
}

final class SlideShowViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case play
        case pause
        case initialPhotoLoaded
        case resetTimer
        case restart
        case showLoader
    }
    
    private var dataSource: SlideShowDataSourceProtocol
    private let slideShowUseCase: SlideShowUseCaseProtocol
    
    var configuration: SlideShowConfigurationEntity
    
    var invokeCommand: ((Command) -> Void)?
    
    var playbackStatus: SlideshowPlaybackStatus = .initialized
    
    var numberOfSlideShowContents: Int {
        dataSource.nodeEntities.count
    }
    
    var photos: [SlideShowMediaEntity] {
        dataSource.photos
    }
        
    var timeIntervalForSlideInSeconds: Double {
        configuration.timeIntervalForSlideInSeconds.value
    }
    
    var currentSlideNumber = 0 {
        didSet {
            dataSource.processData(basedOnCurrentSlideNumber: currentSlideNumber, andOldSlideNumber: oldValue)
        }
    }
    
    init(dataSource: SlideShowDataSourceProtocol,
         slideShowUseCase: SlideShowUseCaseProtocol) {
        
        self.dataSource = dataSource
        self.slideShowUseCase = slideShowUseCase
        
        configuration = slideShowUseCase.loadConfiguration()
        
        dataSource.sortNodes(byOrder: configuration.playingOrder)
        
        if dataSource.loadSelectedPhotoPreview() {
            dataSource.startInitialDownload(true)
            invokeCommand?(.initialPhotoLoaded)
        } else {
            dataSource.startInitialDownload(false)
        }
    }
    
    private func playOrPauseSlideShow() {
        playbackStatus == .playing ? pauseSlideShow() : resumeSlideShow()
    }
    
    func pauseSlideShow() {
        playbackStatus = .pause
        invokeCommand?(.pause)
    }
    
    func resumeSlideShow() {
        playbackStatus = .playing
        invokeCommand?(.play)
    }
    
    func restartSlideShow() {
        invokeCommand?(.showLoader)
        dataSource.initialPhotoDownloadCallback = { [weak self] in
            self?.currentSlideNumber = 0
            self?.invokeCommand?(.restart)
        }
        dataSource.resetData()
    }
    
    func photo(at indexPath: IndexPath) -> UIImage? {
        photos.indices.contains(indexPath.row) ? photos[indexPath.row].image : nil
    }
    
    func dispatch(_ action: SlideShowAction) {
        switch action {
        case .play:
            resumeSlideShow()
        case .pause:
            pauseSlideShow()
        case .finish:
            playbackStatus = .complete
            invokeCommand?(.pause)
        case .resetTimer:
            invokeCommand?(.resetTimer)
        }
    }
}

// MARK: - SlideShowViewModelPreferenceProtocol
extension SlideShowViewModel: SlideShowViewModelPreferenceProtocol {
    func pause() {
        pauseSlideShow()
    }
    
    func cancel() {
        resumeSlideShow()
    }
    
    func restart(withConfig config: SlideShowConfigurationEntity) {
        slideShowUseCase.saveConfiguration(config)

        if config.playingOrder != configuration.playingOrder {
            dataSource.sortNodes(byOrder: config.playingOrder)
            configuration = config
            restartSlideShow()
        } else {
            configuration = config != configuration ? config : configuration
            resumeSlideShow()
        }
    }
}
