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
    private let statusSubject = CurrentValueSubject<PlaybackStatus, Never>(.idle)
    private let isAirPlayActiveSubject = CurrentValueSubject<Bool, Never>(false)
    private let repeatModeSubject = CurrentValueSubject<RepeatMode, Never>(.off)
    private let sleepTimerStateSubject = CurrentValueSubject<SleepTimerState, Never>(.inactive)
    private let isShuffleOnSubject = CurrentValueSubject<Bool, Never>(false)
    private let resumePromptSubject = CurrentValueSubject<ResumePrompt?, Never>(nil)
    private let playbackBlockedSubject = CurrentValueSubject<PlaybackBlockedReason?, Never>(nil)

    private let artworkResolvedSubject = CurrentValueSubject<Bool, Never>(false)

    private let hasStartedPlaybackSubject = CurrentValueSubject<Bool, Never>(false)

    private let trackResolver: any AudioTrackResolutionUseCaseProtocol
    private let streamingRepository: any AudioStreamingRepositoryProtocol
    private let metadataCache: any AudioMetadataCacheProtocol
    private let engine: any PlaybackEngineProtocol
    private let notificationCenter: NotificationCenter
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol

    /// In-flight metadata parse for the current track. Cancelled when a new
    /// track starts or playback stops.
    private var metadataTask: Task<Void, Never>?

    /// In-flight admission check for the current track. Cancelled whenever a new
    /// track starts, so a late verdict cannot land on the wrong one.
    private var resolutionTask: Task<Void, Never>?

    private var sleepTimerTask: Task<Void, Never>?

    /// Bumped on every `play` / `stop` so a late-returning metadata parse for a
    /// superseded track can detect it lost the race and drop its result.
    private var playGeneration = 0
    
    /// The queue's pre-shuffle track order, kept while shuffle is on
    private var unshuffledTracks: [PlaybackTrack]?

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
        /// How close to `duration` counts as "the track has run out" — the
        /// reported position rarely lands exactly on `duration`.
        static let endOfTrackTolerance: TimeInterval = 0.1
    }

    init(
        trackResolver: some AudioTrackResolutionUseCaseProtocol = AudioTrackResolutionUseCase(),
        streamingRepository: some AudioStreamingRepositoryProtocol = DependencyInjection.streamingRepository,
        metadataCache: some AudioMetadataCacheProtocol = AudioMetadataCache(),
        engine: some PlaybackEngineProtocol = PlaybackEngine(),
        notificationCenter: NotificationCenter = .default,
        playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol = DependencyInjection.playbackContinuationUseCase
    ) {
        self.trackResolver = trackResolver
        self.streamingRepository = streamingRepository
        self.metadataCache = metadataCache
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
        self.status = status
        if status == .playing { hasStartedPlaybackSubject.send(true) }
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
        case let .account(node): return node.fingerprint
        case let .folderLink(node): return node.fingerprint
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

    func metadata(forTrackID id: String) async -> AudioMetadata? {
        guard let track = queueSubject.value.tracks.first(where: { $0.id == id }) else { return nil }
        return await metadataCache.metadata(for: track)
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

    var hasStartedPlayback: Bool {
        hasStartedPlaybackSubject.value
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

    var hasStartedPlaybackPublisher: AnyPublisher<Bool, Never> {
        hasStartedPlaybackSubject.removeDuplicates().eraseToAnyPublisher()
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

    var playbackBlockedPublisher: AnyPublisher<PlaybackBlockedReason?, Never> {
        playbackBlockedSubject.removeDuplicates().eraseToAnyPublisher()
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
        unshuffledTracks = nil
        isShuffleOnSubject.send(false)
        trackResolver.reset()
        playbackQueue = PlaybackQueueBuilder.build(from: source)

        startStreamingServerIfNeeded(for: source)
        playCurrent()
        evaluateResumeWhenReady()
    }

    private func playCurrent() {
        metadataTask?.cancel()
        metadataTask = nil
        resolutionTask?.cancel()
        resolutionTask = nil
        playGeneration += 1
        let generation = playGeneration

        playbackBlockedSubject.send(nil)

        guard let track = playbackQueue.current else {
            status = .error("url resolution error")
            return
        }

        title = track.displayName
        artist = nil
        artworkData = nil
        artworkResolvedSubject.send(false)
        hasStartedPlaybackSubject.send(false)
        // The queue has already moved on, so the outgoing track must go quiet now
        // rather than play on — and keep driving the scrubber — for however long the
        // admission check takes.
        engine.unloadCurrentItem()

        // A verdict we already hold is applied inline, so offline files and
        // already-checked tracks start without waiting a turn.
        if let known = trackResolver.cachedResolution(for: track) {
            playTrack(track, resolution: known, generation: generation)
            return
        }

        resolutionTask = Task { [weak self] in
            guard let self else { return }
            let resolution = await trackResolver.resolve(track)
            guard !Task.isCancelled, generation == playGeneration else { return }
            playTrack(track, resolution: resolution, generation: generation)
        }
    }

    private func playTrack(_ track: PlaybackTrack, resolution: AudioURLResolution, generation: Int) {
        switch resolution {
        case .resolved(let url):
            metadataTask = Task { [metadataCache, weak self] in
                let metadata = await metadataCache.metadata(for: track, throttled: false)
                guard let self, !Task.isCancelled else { return }
                if let metadata, !metadata.isEmpty {
                    self.applyMetadata(metadata, generation: generation)
                }
                self.markArtworkResolved(generation: generation)
            }
            engine.play(url: url)

        case .takenDown:
            playbackBlockedSubject.send(.takenDown)

        case .unresolved:
            status = .error("url resolution error")
        }
    }

    func togglePlayPause() {
        if status == .paused, isAtEndOfQueue {
            advanceToNextTrack(wrapAround: true)
        } else {
            engine.togglePlayPause()
        }
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
        advanceToNextTrack(wrapAround: true)
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

    /// Drops a track from the queue and re-anchors the index on whatever is playing
    @discardableResult
    func removeTrack(withID id: String) -> Bool {
        let queue = playbackQueue
        guard let index = queue.tracks.firstIndex(where: { $0.id == id }),
              index != queue.currentIndex else { return false }

        var tracks = queue.tracks
        tracks.remove(at: index)
        let currentID = queue.current?.id
        let currentIndex = currentID
            .flatMap { current in tracks.firstIndex { $0.id == current } }
            ?? queue.currentIndex
        playbackQueue = PlaybackQueue(tracks: tracks, currentIndex: currentIndex)
        unshuffledTracks = unshuffledTracks?.filter { $0.id != id }
        return true
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
            // On the last track the engine has already stopped at the end;
            // leaving the playhead there makes the scrubber read as "finished"
            // and the next play tap restart the queue.
            if !isOnLastTrack {
                advanceToNextTrack(wrapAround: false)
            }
        }
    }

    private var isOnLastTrack: Bool {
        let queue = playbackQueue
        return !queue.tracks.isEmpty && queue.currentIndex >= queue.tracks.count - 1
    }

    /// `true` when the playhead has run out on the last track with repeat off —
    /// the queue is finished, so play means "next + play" rather than "resume".
    private var isAtEndOfQueue: Bool {
        guard repeatMode == .off, isOnLastTrack,
              let duration = engine.duration,
              duration > Constants.endOfTrackTolerance else { return false }
        return engine.currentTime >= duration - Constants.endOfTrackTolerance
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
        unshuffledTracks = queue.tracks

        let played = queue.tracks[...queue.currentIndex]
        let upcoming = queue.tracks[(queue.currentIndex + 1)...].shuffled()
        playbackQueue = PlaybackQueue(
            tracks: Array(played) + upcoming,
            currentIndex: queue.currentIndex
        )
    }

    private func restoreOriginalOrder() {
        guard let originalTracks = unshuffledTracks else { return }
        unshuffledTracks = nil
        let currentID = playbackQueue.current?.id
        let restoredIndex = originalTracks.firstIndex { $0.id == currentID } ?? playbackQueue.currentIndex
        playbackQueue = PlaybackQueue(tracks: originalTracks, currentIndex: restoredIndex)
    }

    func resumeFromPrompt() {
        guard let prompt = resumePromptSubject.value else { return }
        playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
        removeSavedPositionForCurrentTrack()
        engine.seek(toSeconds: prompt.playbackTime)
        engine.togglePlayPause()
        resumePromptSubject.send(nil)
    }

    func restartFromPrompt() {
        guard resumePromptSubject.value != nil else { return }
        playbackContinuationUseCase.setPreference(to: .restartFromBeginning)
        removeSavedPositionForCurrentTrack()
        engine.seek(toSeconds: 0)
        engine.togglePlayPause()
        resumePromptSubject.send(nil)
    }

    private func removeSavedPositionForCurrentTrack() {
        guard let fingerprint = currentTrackFingerprint else { return }
        playbackContinuationUseCase.removeSavedPlaybackPosition(for: fingerprint)
    }

    func stop() {
        guard currentSource != nil else { return }
        
        currentSource = nil
        saveCurrentPlaybackPositionIfNeeded()
        clearResumeState()
        metadataTask?.cancel()
        metadataTask = nil
        resolutionTask?.cancel()
        resolutionTask = nil
        trackResolver.reset()
        playbackBlockedSubject.send(nil)
        Task { [metadataCache] in await metadataCache.removeAll() }
        playGeneration += 1
        unshuffledTracks = nil
        isShuffleOnSubject.send(false)
        playbackQueue = .empty
        title = ""
        artist = nil
        artworkData = nil
        artworkResolvedSubject.send(false)
        hasStartedPlaybackSubject.send(false)
        repeatModeSubject.send(.off)
        status = .idle
        cancelSleepTimer()
        engine.stop()
        streamingRepository.stopServer()
    }
}
