import AVFoundation
import Combine
import Foundation
import MEGADomain

@MainActor
final class AudioPlaybackService {
    static let shared = AudioPlaybackService()

    private let currentSourceSubject = CurrentValueSubject<PlaybackSource?, Never>(nil)
    private let queueSubject = CurrentValueSubject<PlaybackQueue, Never>(.empty)
    private let titleSubject = CurrentValueSubject<String, Never>("")
    private let artistSubject = CurrentValueSubject<String?, Never>(nil)
    private let artworkDataSubject = CurrentValueSubject<Data?, Never>(nil)
    private let statusSubject = CurrentValueSubject<PlaybackStatus, Never>(.loading)
    private let isAirPlayActiveSubject = CurrentValueSubject<Bool, Never>(false)
    private let repeatModeSubject = CurrentValueSubject<RepeatMode, Never>(.off)
    private let sleepTimerStateSubject = CurrentValueSubject<SleepTimerState, Never>(.inactive)
    private let isShuffleOnSubject = CurrentValueSubject<Bool, Never>(false)
    private let resumePromptSubject = CurrentValueSubject<ResumePrompt?, Never>(nil)

    private let hasPlayedOnceBeforeSubject = CurrentValueSubject<Bool, Never>(false)

    private let artworkResolvedSubject = CurrentValueSubject<Bool, Never>(false)

    private let urlResolutionUseCase: any AudioURLResolutionUseCaseProtocol
    private let streamingRepository: any AudioStreamingRepositoryProtocol
    private let metadataLoader: any AudioMetadataLoading
    private let engine: any PlaybackEngineProtocol
    private let notificationCenter: NotificationCenter
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol

    /// In-flight metadata parse for the current track. Cancelled when a new
    /// track starts or playback stops.
    private var metadataTask: Task<Void, Never>?
    
    private var sleepTimerTask: Task<Void, Never>?

    /// Bumped on every `play` / `stop` so a late-returning metadata parse for a
    /// superseded track can detect it lost the race and drop its result.
    private var playGeneration = 0
    
    /// Snapshot of the queue in its pre-shuffle order, kept while shuffle is on
    private var unshuffledQueue: PlaybackQueue?

    private var resumeEvaluationCancellable: AnyCancellable?
    
    private var playbackQueue: PlaybackQueue {
        get { queueSubject.value }
        set { queueSubject.send(newValue) }
    }

    private var cancellables: Set<AnyCancellable> = []

    /// Bridges playback state to the Control Center / lock screen Now Playing UI
    /// and routes its remote commands back into this service.
    private var nowPlayingController: NowPlayingInfoController?

    private enum Constants {
        static let minimumResumableDuration: TimeInterval = 6 * 60
    }

    init(
        urlResolutionUseCase: some AudioURLResolutionUseCaseProtocol = DependencyInjection.urlResolutionUseCase,
        streamingRepository: some AudioStreamingRepositoryProtocol = DependencyInjection.streamingRepository,
        metadataLoader: some AudioMetadataLoading = AudioMetadataLoader(),
        engine: some PlaybackEngineProtocol = PlaybackEngine(),
        notificationCenter: NotificationCenter = .default,
        playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol = DependencyInjection.playbackContinuationUseCase
    ) {
        self.urlResolutionUseCase = urlResolutionUseCase
        self.streamingRepository = streamingRepository
        self.metadataLoader = metadataLoader
        self.engine = engine
        self.notificationCenter = notificationCenter
        self.playbackContinuationUseCase = playbackContinuationUseCase
        bindEngineToState()
        observeAirPlayRouteChanges()
        setUpNowPlaying()
    }
    
    func appWillTerminate() {
        saveCurrentPlaybackPositionIfNeeded()
    }

    // MARK: - Private

    private func setUpNowPlaying() {
        let controller = NowPlayingInfoController(
            commands: .init(
                togglePlayPause: { [weak self] in self?.togglePlayPause() },
                next: { [weak self] in self?.playNext() },
                previous: { [weak self] in self?.playPrevious() },
                seek: { [weak self] in self?.seek(toSeconds: $0) }
            )
        )
        controller.observe(self)
        nowPlayingController = controller
    }
    
    private func markArtworkResolved(generation: Int) {
        guard generation == playGeneration, currentSource != nil else { return }
        artworkResolvedSubject.send(true)
    }

    private func applyMetadata(_ metadata: AudioMetadata, generation: Int) {
        guard generation == playGeneration, currentSource != nil else { return }
        if let title = metadata.title, !title.isEmpty {
            self.title = title
        }
        artist = metadata.artist
        artworkData = metadata.artworkData
    }

    private func startStreamingServerIfNeeded(for source: PlaybackSource) {
        if case .offlineFiles = source { return }
        guard !streamingRepository.isServerRunning else { return }
        streamingRepository.startServer()
    }

    private func bindEngineToState() {
        engine.playbackStatusPublisher
            .sink { [weak self] in self?.applyEngineStatus($0) }
            .store(in: &cancellables)

        engine.didPlayToEndPublisher
            .sink { [weak self] in self?.handleTrackFinished() }
            .store(in: &cancellables)
    }

    /// Pause playback and tear down the active sleep timer.
    private func fireSleepTimer() {
        engine.pause()
        cancelSleepTimer()
    }

    private func observeAirPlayRouteChanges() {
        updateAirPlayState()
        notificationCenter.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateAirPlayState() }
            .store(in: &cancellables)
    }

    private func updateAirPlayState() {
        isAirPlayActive = Self.detectAirPlayRoute()
    }

    private static func detectAirPlayRoute() -> Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .airPlay }
    }

    /// The engine drives `status` during playback, but only while a session is
    /// active — a post-`stop()` `.paused` from the engine must not resurrect a
    /// cleared session.
    private func applyEngineStatus(_ status: PlaybackStatus) {
        guard currentSource != nil else { return }
        if status == .playing { hasPlayedOnceBeforeSubject.send(true) }
        self.status = status
    }

    private func saveCurrentPlaybackPositionIfNeeded() {
        guard let fingerprint = currentTrackFingerprint,
              let duration = engine.duration,
              duration > Constants.minimumResumableDuration else {
            return
        }
        playbackContinuationUseCase.playbackStopped(
            for: fingerprint,
            on: engine.currentTime,
            outOf: duration
        )
    }

    private var currentTrackFingerprint: FingerprintEntity? {
        guard let track = playbackQueue.current else { return nil }
        switch track {
        case let .account(node), let .folderLink(node): return node.fingerprint
        case let .fileLink(_, node): return node?.fingerprint
        case .offline: return nil
        }
    }

    // MARK: - Resume prompt

    private func evaluateResumeWhenReady() {
        clearResumeState()
        if case .error = status { return }
        guard let fingerprint = currentTrackFingerprint,
              let fileName = playbackQueue.current?.displayName else { return }
        let generation = playGeneration

        resumeEvaluationCancellable = engine.durationPublisher
            .compactMap { $0 }
            .first()
            .sink { [weak self] _ in
                guard let self, playGeneration == generation else { return }
                switch playbackContinuationUseCase.status(for: fingerprint) {
                case .startFromBeginning:
                    break
                case .resumeSession(let playbackTime):
                    engine.seek(toSeconds: playbackTime)
                case .displayDialog(let playbackTime):
                    engine.pause()
                    resumePromptSubject.send(
                        ResumePrompt(fileName: fileName, playbackTime: playbackTime)
                    )
                }
            }
    }

    private func clearResumeState() {
        resumeEvaluationCancellable = nil
        resumePromptSubject.send(nil)
    }

}

// MARK: - PlaybackStateObservable

extension AudioPlaybackService: PlaybackStateObservable {
    private(set) var currentSource: PlaybackSource? {
        get { currentSourceSubject.value }
        set { currentSourceSubject.send(newValue) }
    }

    var currentQueue: PlaybackQueue {
        queueSubject.value
    }

    private(set) var title: String {
        get { titleSubject.value }
        set { titleSubject.send(newValue) }
    }

    private(set) var artist: String? {
        get { artistSubject.value }
        set { artistSubject.send(newValue) }
    }

    private(set) var artworkData: Data? {
        get { artworkDataSubject.value }
        set { artworkDataSubject.send(newValue) }
    }

    private(set) var status: PlaybackStatus {
        get { statusSubject.value }
        set { statusSubject.send(newValue) }
    }

    var hasPlayedOnceBefore: Bool {
        hasPlayedOnceBeforeSubject.value
    }

    var artworkResolved: Bool {
        artworkResolvedSubject.value
    }

    private(set) var isAirPlayActive: Bool {
        get { isAirPlayActiveSubject.value }
        set { isAirPlayActiveSubject.send(newValue) }
    }

    var repeatMode: RepeatMode {
        repeatModeSubject.value
    }
    
    private(set) var sleepTimerState: SleepTimerState {
        get { sleepTimerStateSubject.value }
        set { sleepTimerStateSubject.send(newValue) }
    }
    
    var isShuffleOn: Bool {
        isShuffleOnSubject.value
    }

    var currentSourcePublisher: AnyPublisher<PlaybackSource?, Never> {
        currentSourceSubject.eraseToAnyPublisher()
    }

    var currentQueuePublisher: AnyPublisher<PlaybackQueue, Never> {
        queueSubject.eraseToAnyPublisher()
    }

    var titlePublisher: AnyPublisher<String, Never> {
        titleSubject.eraseToAnyPublisher()
    }

    var artistPublisher: AnyPublisher<String?, Never> {
        artistSubject.eraseToAnyPublisher()
    }

    var artworkDataPublisher: AnyPublisher<Data?, Never> {
        artworkDataSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<TimeInterval?, Never> {
        engine.durationPublisher
    }

    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        engine.currentTimePublisher
    }

    var statusPublisher: AnyPublisher<PlaybackStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    var hasPlayedOnceBeforePublisher: AnyPublisher<Bool, Never> {
        hasPlayedOnceBeforeSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var artworkResolvedPublisher: AnyPublisher<Bool, Never> {
        artworkResolvedSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var isAirPlayActivePublisher: AnyPublisher<Bool, Never> {
        isAirPlayActiveSubject.removeDuplicates().eraseToAnyPublisher()
    }
    
    var playbackSpeedPublisher: AnyPublisher<Float, Never> {
        engine.playbackSpeedPublisher
    }

    var playbackRatePublisher: AnyPublisher<Float, Never> {
        engine.playbackRatePublisher
    }

    var repeatModePublisher: AnyPublisher<RepeatMode, Never> {
        repeatModeSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var sleepTimerStatePublisher: AnyPublisher<SleepTimerState, Never> {
        sleepTimerStateSubject.removeDuplicates().eraseToAnyPublisher()
    }
    
    var isShuffleOnPublisher: AnyPublisher<Bool, Never> {
        isShuffleOnSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var resumePromptPublisher: AnyPublisher<ResumePrompt?, Never> {
        resumePromptSubject.removeDuplicates().eraseToAnyPublisher()
    }
}

// MARK: - PlaybackControllable

extension AudioPlaybackService: PlaybackControllable {
    func play(source: PlaybackSource) {
        if currentSource != nil, source.initialTrack.id == playbackQueue.current?.id {
            return
        }

        saveCurrentPlaybackPositionIfNeeded()
        currentSource = source
        unshuffledQueue = nil
        isShuffleOnSubject.send(false)
        playbackQueue = PlaybackQueueBuilder.build(from: source)

        startStreamingServerIfNeeded(for: source)
        playCurrent()
        evaluateResumeWhenReady()
    }

    private func playCurrent() {
        metadataTask?.cancel()
        metadataTask = nil
        playGeneration += 1
        let generation = playGeneration

        guard let track = playbackQueue.current else {
            status = .error("url resolution error")
            return
        }

        title = track.displayName
        artist = nil
        artworkData = nil
        hasPlayedOnceBeforeSubject.send(false)
        artworkResolvedSubject.send(false)
        status = .loading

        guard let url = urlResolutionUseCase.url(for: track) else {
            status = .error("url resolution error")
            return
        }
        metadataTask = Task { [metadataLoader, weak self] in
            let metadata = try? await metadataLoader.loadMetadata(from: url)
            guard let self, !Task.isCancelled else { return }
            if let metadata, !metadata.isEmpty {
                self.applyMetadata(metadata, generation: generation)
            }
            self.markArtworkResolved(generation: generation)
        }
        engine.play(url: url)
    }

    func togglePlayPause() {
        engine.togglePlayPause()
    }

    func seek(toSeconds seconds: TimeInterval) {
        engine.seek(toSeconds: seconds)
    }

    func playPrevious() {
        guard playbackQueue.currentIndex > 0 else {
            engine.seek(toSeconds: 0)
            return
        }
        saveCurrentPlaybackPositionIfNeeded()
        playbackQueue = PlaybackQueue(
            tracks: playbackQueue.tracks,
            currentIndex: playbackQueue.currentIndex - 1
        )
        playCurrent()
    }

    func playNext() {
        saveCurrentPlaybackPositionIfNeeded()
        advanceToNextTrack(wrapAround: repeatModeSubject.value == .all)
    }

    func play(atIndex index: Int) {
        guard playbackQueue.tracks.indices.contains(index),
              index != playbackQueue.currentIndex else { return }
        saveCurrentPlaybackPositionIfNeeded()
        playbackQueue = PlaybackQueue(
            tracks: playbackQueue.tracks,
            currentIndex: index
        )
        playCurrent()
    }

    func setPlaybackSpeed(_ rate: Float) {
        engine.setPlaybackSpeed(rate)
    }

    func move(from source: Int, toOffset destination: Int) {
        playbackQueue = playbackQueue.moving(from: source, toOffset: destination)
    }

    func cycleRepeat() {
        repeatModeSubject.send(repeatModeSubject.value.next)
    }

    private func handleTrackFinished() {
        guard currentSource != nil else { return }

        saveCurrentPlaybackPositionIfNeeded()

        if sleepTimerState == .endOfTrack {
            fireSleepTimer()
            return
        }

        switch repeatModeSubject.value {
        case .one:
            engine.replay()
        case .all:
            advanceToNextTrack(wrapAround: true)
        case .off:
            advanceToNextTrack(wrapAround: false)
        }
    }

    private func advanceToNextTrack(wrapAround: Bool) {
        let queue = playbackQueue
        let nextIndex = queue.currentIndex + 1
        if queue.tracks.indices.contains(nextIndex) {
            playbackQueue = PlaybackQueue(tracks: queue.tracks, currentIndex: nextIndex)
            playCurrent()
        } else if wrapAround, !queue.tracks.isEmpty {
            playbackQueue = PlaybackQueue(tracks: queue.tracks, currentIndex: 0)
            playCurrent()
        }
    }

    func startSleepTimer(after interval: TimeInterval) {
        sleepTimerState = .countdown(deadline: Date().addingTimeInterval(interval))
        sleepTimerTask?.cancel()
        sleepTimerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            self?.fireSleepTimer()
        }
    }

    func startSleepTimerAtEndOfTrack() {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerState = .endOfTrack
    }

    func cancelSleepTimer() {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerState = .inactive
    }

    func toggleShuffle() {
        if isShuffleOnSubject.value {
            restoreOriginalOrder()
            isShuffleOnSubject.send(false)
        } else {
            guard playbackQueue.current != nil else { return }
            shuffleUpcoming()
            isShuffleOnSubject.send(true)
        }
    }

    private func shuffleUpcoming() {
        let queue = playbackQueue
        guard queue.current != nil else { return }
        unshuffledQueue = queue

        let played = queue.tracks[...queue.currentIndex]
        let upcoming = queue.tracks[(queue.currentIndex + 1)...].shuffled()
        playbackQueue = PlaybackQueue(
            tracks: Array(played) + upcoming,
            currentIndex: queue.currentIndex
        )
    }

    private func restoreOriginalOrder() {
        guard let original = unshuffledQueue else { return }
        unshuffledQueue = nil
        let currentID = playbackQueue.current?.id
        let restoredIndex = original.tracks.firstIndex { $0.id == currentID } ?? original.currentIndex
        playbackQueue = PlaybackQueue(tracks: original.tracks, currentIndex: restoredIndex)
    }

    func resumeFromPrompt() {
        guard let prompt = resumePromptSubject.value else { return }
        playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
        engine.seek(toSeconds: prompt.playbackTime)
        engine.togglePlayPause()
        resumePromptSubject.send(nil)
    }

    func restartFromPrompt() {
        guard resumePromptSubject.value != nil else { return }
        playbackContinuationUseCase.setPreference(to: .restartFromBeginning)
        engine.seek(toSeconds: 0)
        engine.togglePlayPause()
        resumePromptSubject.send(nil)
    }

    func stop() {
        saveCurrentPlaybackPositionIfNeeded()
        clearResumeState()
        metadataTask?.cancel()
        metadataTask = nil
        playGeneration += 1
        currentSource = nil
        unshuffledQueue = nil
        isShuffleOnSubject.send(false)
        playbackQueue = .empty
        title = ""
        artist = nil
        artworkData = nil
        hasPlayedOnceBeforeSubject.send(false)
        artworkResolvedSubject.send(false)
        repeatModeSubject.send(.off)
        status = .loading
        cancelSleepTimer()
        engine.stop()
        streamingRepository.stopServer()
    }
}
