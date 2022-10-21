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
    func restart(withConfig config: SlideShowViewConfiguration)
}

final class SlideShowViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case play
        case pause
        case initialPhotoLoaded
        case resetTimer
        case restart
    }
    
    private var dataSource: SlideShowDataSourceProtocol

    var configuration: SlideShowViewConfiguration
    
    var invokeCommand: ((Command) -> Void)?
    
    var playbackStatus: SlideshowPlaybackStatus = .initialized {
        didSet {
            if playbackStatus == .complete {
                dataSource.slideshowComplete = true
            }
        }
    }
    
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
    
    init(
        dataSource: SlideShowDataSourceProtocol,
        configuration: SlideShowViewConfiguration
    ) {
        self.dataSource = dataSource
        self.configuration = configuration
        
        dataSource.sortNodes(byOrder: configuration.playingOrder)
        
        if dataSource.loadSelectedPhotoPreview() {
            dataSource.startInitialDownload(true)
            invokeCommand?(.initialPhotoLoaded)
        } else {
            dataSource.startInitialDownload(false)
        }
    }
    
    private func playOrPauseSlideShow() {
        guard playbackStatus == .playing
        else {
            playbackStatus = .playing
            invokeCommand?(.play)
            return
        }
        
        playbackStatus = .pause
        invokeCommand?(.pause)
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
        dataSource.photos.removeAll()
        dataSource.startInitialDownload(false)
        playbackStatus = .playing
        currentSlideNumber = -1
        invokeCommand?(.restart)
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
    
    func restart(withConfig config: SlideShowViewConfiguration) {
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
