import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGASwiftUI

enum SlideShowAction: ActionType {
    case play
    case pause
    case finish
    case resetTimer
    case viewDidAppear
    case onViewReady
    case onViewWillDisappear
}

protocol SlideShowViewModelPreferenceProtocol {
    func pause()
    func cancel()
    func restart(withConfig config: SlideShowConfigurationEntity)
}

final class SlideShowViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case adjustHeightOfTopAndBottomViews
        case play
        case pause
        case initialPhotoLoaded
        case hideLoader
        case resetTimer
        case restart
        case showLoader
    }
    
    private let dataSource: any SlideShowDataSourceProtocol
    private let slideShowUseCase: any SlideShowUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let notificationCenter: NotificationCenter
    
    private var willResignActiveNotificationTask: Task<Void, Never>?
    private var didBecomeActiveNotificationNotificationTask: Task<Void, Never>?

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
         slideShowUseCase: some SlideShowUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         tracker: some AnalyticsTracking,
         notificationCenter: NotificationCenter = .default
    ) {
        self.dataSource = dataSource
        self.slideShowUseCase = slideShowUseCase
        self.accountUseCase = accountUseCase
        self.tracker = tracker
        self.notificationCenter = notificationCenter

        if let userHandle = accountUseCase.currentUserHandle {
            configuration = slideShowUseCase.loadConfiguration(forUser: userHandle)
        } else {
            configuration = slideShowUseCase.defaultConfig
        }
        
        dataSource.sortNodes(byOrder: configuration.playingOrder)
        self.currentSlideIndex = dataSource.indexOfCurrentPhoto()
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
        case .onViewReady:
            subscribeToWillResignActiveNotificationNotification()
            subscribeToDidBecomeActiveNotificationNotification()
            invokeCommand?(.showLoader)
            loadPhotos()
        case .onViewWillDisappear:
            willResignActiveNotificationTask?.cancel()
            didBecomeActiveNotificationNotificationTask?.cancel()
        }
    }

    private func loadPhotos() {
        dataSource.loadSelectedPhotoPreview { [weak self] in
            guard let self else { return }
            invokeCommand?(.hideLoader)
            invokeCommand?(.initialPhotoLoaded)
        }
        dataSource.download(fromCurrentIndex: currentSlideIndex)
    }

    private func sendScreenEvent() {
        tracker.trackAnalyticsEvent(with: SlideShowScreenEvent())
    }
    
    private func subscribeToWillResignActiveNotificationNotification() {
        willResignActiveNotificationTask = Task(priority: .utility) { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: UIApplication.willResignActiveNotification).map({ _ in () }) {
                self?.pauseSlideShow()
                self?.invokeCommand?(.hideLoader)
            }
        }
    }
    
    private func subscribeToDidBecomeActiveNotificationNotification() {
        didBecomeActiveNotificationNotificationTask = Task { [notificationCenter, invokeCommand] in
            for await _ in notificationCenter.notifications(
                named: UIApplication.didBecomeActiveNotification).map({ _ in () }) {
                invokeCommand?(.adjustHeightOfTopAndBottomViews)
            }
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
