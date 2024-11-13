import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASwiftUI

enum SlideShowAction: ActionType {
    case play
    case pause
    case finish
    case resetTimer
    case viewDidAppear
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
    
    private var dataSource: any SlideShowDataSourceProtocol
    private let slideShowUseCase: any SlideShowUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    var configuration: SlideShowConfigurationEntity
    
    var invokeCommand: ((Command) -> Void)?
    
    var playbackStatus: SlideshowPlaybackStatus = .initialized
    
    var numberOfSlideShowContents: Int {
        dataSource.count
    }
     
    var timeIntervalForSlideInSeconds: Double {
        configuration.timeIntervalForSlideInSeconds.value
    }
    
    var currentSlideIndex: Int {
        didSet {
            dataSource.download(fromCurrentIndex: currentSlideIndex)
        }
    }
    
    init(dataSource: some SlideShowDataSourceProtocol,
         slideShowUseCase: any SlideShowUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         tracker: some AnalyticsTracking) {
        
        self.dataSource = dataSource
        self.slideShowUseCase = slideShowUseCase
        self.accountUseCase = accountUseCase
        self.tracker = tracker
        
        if let userHandle = accountUseCase.currentUserHandle {
            configuration = slideShowUseCase.loadConfiguration(forUser: userHandle)
        } else {
            configuration = slideShowUseCase.defaultConfig
        }
        
        dataSource.sortNodes(byOrder: configuration.playingOrder)
        
        self.currentSlideIndex = dataSource.indexOfCurrentPhoto()
        
        dataSource.loadSelectedPhotoPreview()
        invokeCommand?(.initialPhotoLoaded)
        dataSource.download(fromCurrentIndex: currentSlideIndex)
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
        currentSlideIndex = dataSource.indexOfCurrentPhoto()
        invokeCommand?(.restart)
    }
        
    func mediaEntity(at indexPath: IndexPath) -> SlideShowCellViewModel? {
        dataSource.items[indexPath.row]
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
        case .viewDidAppear:
            sendScreenEvent()
        }
    }
    
    private func sendScreenEvent() {
        tracker.trackAnalyticsEvent(with: SlideShowScreenEvent())
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
        do {
            if let userHandle = accountUseCase.currentUserHandle {
                try slideShowUseCase.saveConfiguration(config: config, forUser: userHandle)
            }
        } catch {
            MEGALogError("Slideshow configuration saving error: \(error)")
        }

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
