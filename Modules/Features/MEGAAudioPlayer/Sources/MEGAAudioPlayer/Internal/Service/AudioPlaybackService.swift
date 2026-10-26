import AVFoundation
import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

@MainActor
final class AudioPlaybackService {
    static let shared = AudioPlaybackService()

    private let currentSourceSubject = CurrentValueSubject<PlaybackSource?, Never>(nil)
    private let queueSubject = CurrentValueSubject<PlaybackQueue, Never>(.empty)
    private let metadataTitleSubject = CurrentValueSubject<String?, Never>(nil)
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
    private let analyticsReporter: AudioPlaybackAnalyticsReporter
    private let audioNodeUpdatesUseCase: any AudioNodeUpdatesUseCaseProtocol
    private let leftOffItemRecordUseCase: (any LeftOffItemRecordUseCaseProtocol)?

    // Expose the task for left off item processing, to be used in test code.
    private(set) var leftOffItemTask: Task<Void, Never>?

    /// In-flight metadata parse for the current track. Cancelled when a new
    /// track starts or playback stops.
    private var metadataTask: Task<Void, Never>?

    /// In-flight admission check for the current track. Cancelled whenever a new
    /// track starts, so a late verdict cannot land on the wrong one.
    private var resolutionTask: Task<Void, Never>?

    private var sleepTimerTask: Task<Void, Never>?

    /// Runs for the lifetime of the service: the SDK keeps reporting node changes
    private var removedNodesTask: Task<Void, Never>?

    /// The folder-link SDK's own stream, which only bears on folder-link playback
    private var removedFolderLinkNodesTask: Task<Void, Never>?

    private var renamedNodesTask: Task<Void, Never>?

    private var renamedFolderLinkNodesTask: Task<Void, Never>?

    /// Bumped on every `play` / `stop` so a late-returning metadata parse for a
    /// superseded track can detect it lost the race and drop its result.
    private var playGeneration = 0

    /// The queue's pre-shuffle track order, kept while shuffle is on
    private var unshuffledTracks: [PlaybackTrack]?

    private var resumeEvaluationCancellable: AnyCancellable?
    
    /// How many other players currently own playback — see `beginInterruption()`. Counted rather than flagged,
    /// as their lifetimes can overlap (a video in Picture in Picture while another one opens).
    private var interruptionCount = 0

    private var isInterrupted: Bool { interruptionCount > 0 }

    /// Whether another player took playback over since the current track started
    private var wasInterruptedDuringTrack = false

    /// The address the current track was handed to the engine with, before any AirPlay rewrite — which
    /// only ever changes the host of a streamed address, never whether it is a file
    private var currentTrackURL: URL?

    /// Whether playback was wanted as the interruption began, so it can pick up again when it ends.
    private var resumesAfterInterruption = false

    /// Set while an interruption keeps automatic starts (a track finishing loading) waiting for it to end;
    /// cleared once the user takes playback over.
    private var holdsAutoplay = false

    private var playbackQueue: PlaybackQueue {
        get { queueSubject.value }
        set {
            // Built here rather than under the lock, which only guards the swap
            let folders = Dictionary(
                newValue.tracks.compactMap { track -> (HandleEntity, HandleEntity)? in
                    guard case .account(let node) = track else { return nil }
                    return (node.handle, node.parentHandle)
                },
                uniquingKeysWith: { first, _ in first }
            )
            queuedFolders.mutate { $0 = folders }
            queueSubject.send(newValue)
        }
    }

    /// The folder each Cloud Drive track's node was in when it was queued or last refreshed, for
    /// the node-update task to read without waiting on the main actor
    private let queuedFolders = Atomic<[HandleEntity: HandleEntity]>(wrappedValue: [:])

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
        playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol = DependencyInjection.playbackContinuationUseCase,
        analyticsReporter: AudioPlaybackAnalyticsReporter = AudioPlaybackAnalyticsReporter(tracker: DependencyInjection.analyticsTracker, accountUseCase: DependencyInjection.accountUseCase),
        audioNodeUpdatesUseCase: some AudioNodeUpdatesUseCaseProtocol = AudioNodeUpdatesUseCase(),
        leftOffItemRecordUseCase: (any LeftOffItemRecordUseCaseProtocol)? = DependencyInjection.leftOffItemRecordUseCase
    ) {
        self.trackResolver = trackResolver
        self.streamingRepository = streamingRepository
        self.metadataCache = metadataCache
        self.engine = engine
        self.notificationCenter = notificationCenter
        self.playbackContinuationUseCase = playbackContinuationUseCase
        self.analyticsReporter = analyticsReporter
        self.audioNodeUpdatesUseCase = audioNodeUpdatesUseCase
        self.leftOffItemRecordUseCase = leftOffItemRecordUseCase
        bindEngineToState()
        observeAirPlayRouteChanges()
        setUpNowPlaying()
        bindNodeUpdates()
    }
    
    func appWillTerminate() {
        saveCurrentPlaybackPositionIfNeeded()
    }

    // MARK: - Interruption

    func beginInterruption() {
        interruptionCount += 1
        wasInterruptedDuringTrack = true
        guard interruptionCount == 1 else { return }
        holdsAutoplay = true
        resumesAfterInterruption = engine.isPlaybackIntended
        if resumesAfterInterruption {
            engine.pause()
        }
        nowPlayingController?.suspend()
    }

    func endInterruption(shouldResume: Bool) {
        guard isInterrupted else { return }
        interruptionCount -= 1
        // Only the last player to step out hands playback back
        guard !isInterrupted else { return }
        holdsAutoplay = false
        nowPlayingController?.resume()
        if shouldResume, resumesAfterInterruption, currentSource != nil, status != .playing {
            engine.togglePlayPause()
        }
        resumesAfterInterruption = false
    }

    /// Drops any interruption left behind, e.g. by a player taken away without ending its playback
    func resetInterruption() {
        guard isInterrupted else { return }
        interruptionCount = 0
        holdsAutoplay = false
        resumesAfterInterruption = false
        nowPlayingController?.resume()
    }

    /// The user starts or stops playback themselves while another player owns it: from here on it is left
    /// as they set it, neither held back nor resumed once the other player is done.
    private func takeOverInterruptedPlayback() {
        guard isInterrupted else { return }
        holdsAutoplay = false
        resumesAfterInterruption = false
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
            metadataTitleSubject.send(title)
        }
        artist = metadata.artist
        artworkData = metadata.artworkData
    }

    private func startStreamingServerIfNeeded(for source: PlaybackSource) {
        switch source {
        case .offlineFiles, .offlineNodes: return
        default: break
        }
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
        // The engine reports failures it can only see after the item is loaded
        if case .error(let reason) = status {
            trackFailure(reason, track: playbackQueue.current, generation: playGeneration)
        }
    }

    // MARK: - Analytics

    private func reportStarted(track: PlaybackTrack, generation: Int) {
        analyticsReporter.trackPlaybackStarted(track: track, generation: generation)
    }

    private func trackFailure(
        _ reason: AudioPlaybackFailureReason,
        track: PlaybackTrack?,
        generation: Int
    ) {
        analyticsReporter.trackPlaybackFailed(
            track: track,
            reason: reason,
            context: AudioPlaybackFailureContext(
                needsStreamingServer: needsStreamingServer(track),
                isStreamingServerRunning: streamingRepository.isServerRunning,
                wasInterrupted: wasInterruptedDuringTrack
            ),
            generation: generation
        )
    }

    /// Whether the track is read through the streaming server: by its address once it has one, otherwise by
    /// its kind — an account node that got no address had no copy on the device to fall back on.
    /// `nil` when there was no track.
    private func needsStreamingServer(_ track: PlaybackTrack?) -> Bool? {
        guard let track else { return nil }
        if let currentTrackURL { return !currentTrackURL.isFileURL }
        return switch track {
        case .account, .folderLink, .fileLink: true
        case .offline, .offlineNode: false
        }
    }

    private func saveCurrentPlaybackPositionIfNeeded() {
        guard let fingerprint = currentTrackFingerprint,
              let duration = engine.duration,
              duration > Constants.minimumResumableDuration else {
            return
        }
        let outcome = playbackContinuationUseCase.playbackStopped(
            for: fingerprint,
            on: engine.currentTime,
            outOf: duration
        )

        processOutcome(outcome: outcome)
    }

    private func processOutcome(outcome: PlaybackContinuationOutcomeEntity) {
        guard let leftOffItemRecordUseCase,
              let (handle, name) = currentTrackHandleAndName else {
            return
        }

        leftOffItemTask = Task {
            switch outcome {
            case .saved: await leftOffItemRecordUseCase.record(handle: handle, name: name)
            case .removed: await leftOffItemRecordUseCase.remove(handle: handle)
            }
        }
    }

    private var currentTrackHandleAndName: (handle: HandleEntity, name: String)? {
        guard let track = playbackQueue.current else { return nil }
        switch track {
        case let .account(node): return (node.handle, node.name)
        case let .folderLink(node): return handleAndName(of: node)
        case let .fileLink(_, node): return node.flatMap { handleAndName(of: $0) }
        case .offline: return nil
        case let .offlineNode(node, _): return (node.handle, node.name)
        }
    }

    private func handleAndName(of node: any PlayableNode) -> (handle: HandleEntity, name: String)? {
        guard let name = node.name else { return nil }
        return (node.handle, name)
    }

    private var currentTrackFingerprint: FingerprintEntity? {
        guard let track = playbackQueue.current else { return nil }
        switch track {
        case let .account(node): return node.fingerprint
        case let .folderLink(node): return node.fingerprint
        case let .fileLink(_, node): return node?.fingerprint
        case .offline: return nil
        case let .offlineNode(node, _): return node.fingerprint
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
    /// The source playback was started with. Stays as passed in — only its presence and
    /// its case are read after the queue is built. For the tracks, use `currentQueue`,
    /// which is the one kept up to date on renames and deletions.
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

    var title: String {
        Self.title(metadataTitle: metadataTitleSubject.value, nodeName: playbackQueue.current?.displayName)
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
        Publishers.CombineLatest(
            metadataTitleSubject,
            queueSubject.map { $0.current?.displayName }
        )
        .map(Self.title(metadataTitle:nodeName:))
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    private static func title(metadataTitle: String?, nodeName: String?) -> String {
        metadataTitle ?? nodeName ?? ""
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
        if currentSource != nil,
           source.initialTrack.playbackIdentity == playbackQueue.current?.playbackIdentity {
            return
        }

        takeOverInterruptedPlayback()
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

    private func playCurrent(autoplay: Bool = true) {
        metadataTask?.cancel()
        metadataTask = nil
        resolutionTask?.cancel()
        resolutionTask = nil
        playGeneration += 1
        let generation = playGeneration

        playbackBlockedSubject.send(nil)

        guard let track = playbackQueue.current else {
            MEGALogError("[AudioPlayer] playCurrent with an empty queue")
            status = .error(.queueEmpty)
            return
        }

        reportStarted(track: track, generation: generation)
        wasInterruptedDuringTrack = isInterrupted
        currentTrackURL = nil

        metadataTitleSubject.send(nil)
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
            playTrack(track, resolution: known, generation: generation, autoplay: autoplay)
            return
        }

        resolutionTask = Task { [weak self] in
            guard let self else { return }
            let resolution = await trackResolver.resolve(track)
            guard !Task.isCancelled, generation == playGeneration else { return }
            playTrack(track, resolution: resolution, generation: generation, autoplay: autoplay)
        }
    }

    private func playTrack(
        _ track: PlaybackTrack,
        resolution: AudioURLResolution,
        generation: Int,
        autoplay: Bool
    ) {
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
            // A track that finishes loading while another player owns playback waits for it to end
            if holdsAutoplay, autoplay {
                resumesAfterInterruption = true
            }
            currentTrackURL = url
            engine.play(url: url, autoplay: autoplay && !holdsAutoplay)

        case .takenDown:
            playbackBlockedSubject.send(.takenDown)
            trackFailure(.takenDown, track: track, generation: generation)

        case .unresolved:
            status = .error(.urlUnresolved)
            trackFailure(.urlUnresolved, track: track, generation: generation)
        }
    }

    func togglePlayPause() {
        takeOverInterruptedPlayback()
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
        takeOverInterruptedPlayback()
        saveCurrentPlaybackPositionIfNeeded()
        playbackQueue = PlaybackQueue(
            tracks: playbackQueue.tracks,
            currentIndex: playbackQueue.currentIndex - 1
        )
        playCurrent()
    }

    func playNext() {
        takeOverInterruptedPlayback()
        saveCurrentPlaybackPositionIfNeeded()
        advanceToNextTrack(wrapAround: true)
    }

    func play(atIndex index: Int) {
        guard playbackQueue.tracks.indices.contains(index),
              index != playbackQueue.currentIndex else { return }
        takeOverInterruptedPlayback()
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

    // MARK: - Node updates

    private func bindNodeUpdates() {
        removedNodesTask = Task.detached { [weak self, audioNodeUpdatesUseCase, queuedFolders] in
            let removedNodes = audioNodeUpdatesUseCase.removedNodes { queuedFolders.wrappedValue }
            for await removals in removedNodes {
                guard !Task.isCancelled else { return }
                await self?.handleRemovedNodes(removals)
            }
        }

        removedFolderLinkNodesTask = Task.detached { [weak self, audioNodeUpdatesUseCase] in
            for await removals in audioNodeUpdatesUseCase.removedFolderLinkNodes {
                guard !Task.isCancelled else { return }
                await self?.handleRemovedFolderLinkNodes(removals)
            }
        }

        renamedNodesTask = Task.detached { [weak self, audioNodeUpdatesUseCase] in
            for await renamedNodes in audioNodeUpdatesUseCase.renamedNodes {
                guard !Task.isCancelled else { return }
                await self?.replaceNodes(isFolderLink: false) { $0.refreshingNodes(renamedNodes) }
            }
        }

        renamedFolderLinkNodesTask = Task.detached { [weak self, audioNodeUpdatesUseCase] in
            for await renamedNodes in audioNodeUpdatesUseCase.renamedFolderLinkNodes {
                guard !Task.isCancelled else { return }
                await self?.replaceNodes(isFolderLink: true) { $0.refreshingFolderLinkNodes(renamedNodes) }
            }
        }
    }

    /// Replacements go in first, as for a folder link
    private func handleRemovedNodes(_ removals: [HandleEntity: NodeEntity?]) {
        let replacements = removals.compactMapValues { $0 }
        if replacements.isNotEmpty {
            replaceNodes(isFolderLink: false) { $0.replacingNodes(replacements) }
        }
        handleDeletedNodes(withHandles: Set(removals.keys), isFolderLink: false)
    }

    /// Replacements go in first, so a deletion that skips the playing track lands on a new file
    /// rather than loading the old one only to restart it. A track whose replacement was turned
    /// down is then deleted along with the rest
    private func handleRemovedFolderLinkNodes(_ removals: [HandleEntity: (any PlayableNode)?]) {
        let replacements = removals.compactMapValues { $0 }
        if replacements.isNotEmpty {
            replaceNodes(isFolderLink: true) { $0.replacingFolderLinkNodes(replacements) }
        }
        handleDeletedNodes(withHandles: Set(removals.keys), isFolderLink: true)
    }

    private func handleDeletedNodes(
        withHandles deletedNodeHandles: Set<HandleEntity>,
        isFolderLink: Bool
    ) {
        guard let currentSource, currentSource.isFolderLink == isFolderLink else { return }

        switch playbackQueue.applyingDeletion(ofNodeHandles: deletedNodeHandles) {
        case .unaffected:
            break

        case .dropped(let queue):
            apply(queue)

        case .skipped(let queue):
            removeSavedPositionForCurrentTrack()
            apply(queue)
            playCurrent()

        case .emptied:
            removeSavedPositionForCurrentTrack()
            stop(savingPosition: false)
        }
    }

    private func replaceNodes(
        isFolderLink: Bool,
        _ replace: ([PlaybackTrack]) -> [PlaybackTrack]?
    ) {
        guard let currentSource, currentSource.isFolderLink == isFolderLink,
              let tracks = replace(playbackQueue.tracks) else { return }

        let playingTrackID = playbackQueue.current?.id
        // Read before `playCurrent` unloads the item, which clears it: unlike the status, it
        // holds through an interruption and a play tapped while the last new file was loading
        let autoplay = engine.isPlaybackIntended
        playbackQueue = PlaybackQueue(tracks: tracks, currentIndex: playbackQueue.currentIndex)
        if let unshuffled = unshuffledTracks.flatMap(replace) {
            unshuffledTracks = unshuffled
        }

        // A track's id is its node's handle: a fresh snapshot keeps it, a replacing file does not
        let isPlayingTrackReplaced = playingTrackID != nil && playbackQueue.current?.id != playingTrackID
        if isPlayingTrackReplaced {
            clearResumeState()
            playCurrent(autoplay: autoplay)
        }
    }

    private func apply(_ queue: PlaybackQueue) {
        playbackQueue = queue
        let survivingIDs = Set(queue.tracks.map(\.id))
        unshuffledTracks = unshuffledTracks?.filter { survivingIDs.contains($0.id) }
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
        stop(savingPosition: true)
    }

    /// - Parameter savingPosition: `false` when the track is going away rather than being left for later
    private func stop(savingPosition: Bool) {
        guard currentSource != nil else { return }
        
        currentSource = nil
        if savingPosition {
            saveCurrentPlaybackPositionIfNeeded()
        }
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
        metadataTitleSubject.send(nil)
        artist = nil
        artworkData = nil
        artworkResolvedSubject.send(false)
        hasStartedPlaybackSubject.send(false)
        repeatModeSubject.send(.off)
        resumesAfterInterruption = false
        status = .idle
        cancelSleepTimer()
        engine.stop()
        streamingRepository.stopServer()
    }
}
