import AVFoundation
import Combine
import Foundation
import MEGADomain

@MainActor
final class AudioPlaybackService {
    static let shared = AudioPlaybackService()

    private let currentSourceSubject = CurrentValueSubject<PlaybackSource?, Never>(nil)
    private let titleSubject = CurrentValueSubject<String, Never>("")
    private let artistSubject = CurrentValueSubject<String?, Never>(nil)
    private let artworkDataSubject = CurrentValueSubject<Data?, Never>(nil)
    private let statusSubject = CurrentValueSubject<PlaybackStatus, Never>(.loading)
    private let isAirPlayActiveSubject = CurrentValueSubject<Bool, Never>(false)

    private let hasPlayedOnceBeforeSubject = CurrentValueSubject<Bool, Never>(false)

    private let artworkResolvedSubject = CurrentValueSubject<Bool, Never>(false)

    private let urlResolutionUseCase: any AudioURLResolutionUseCaseProtocol
    private let streamingRepository: any AudioStreamingRepositoryProtocol
    private let metadataLoader: any AudioMetadataLoading
    private let engine: any PlaybackEngineProtocol

    /// In-flight metadata parse for the current track. Cancelled when a new
    /// track starts or playback stops.
    private var metadataTask: Task<Void, Never>?

    /// Bumped on every `play` / `stop` so a late-returning metadata parse for a
    /// superseded track can detect it lost the race and drop its result.
    private var playGeneration = 0
    
    private var cancellables: Set<AnyCancellable> = []

    init(
        urlResolutionUseCase: some AudioURLResolutionUseCaseProtocol = DependencyInjection.urlResolutionUseCase,
        streamingRepository: some AudioStreamingRepositoryProtocol = DependencyInjection.streamingRepository,
        metadataLoader: some AudioMetadataLoading = AudioMetadataLoader(),
        engine: some PlaybackEngineProtocol = PlaybackEngine()
    ) {
        self.urlResolutionUseCase = urlResolutionUseCase
        self.streamingRepository = streamingRepository
        self.metadataLoader = metadataLoader
        self.engine = engine
        bindEngineToState()
        observeAirPlayRouteChanges()
    }

    // MARK: - Private

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
    }

    private func observeAirPlayRouteChanges() {
        updateAirPlayState()
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
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

    private static func displayName(for source: PlaybackSource) -> String {
        switch source {
        case .cloudNode(let node, _),
             .chatMessage(let node, _, _),
             .folderLink(let node, _),
             .searchResult(let node):
            return node.name
        case .fileLink(_, let node):
            return node?.name ?? ""
        case .offlineFiles(let paths, let startIndex):
            let url = paths.indices.contains(startIndex) ? paths[startIndex] : paths.first
            return url?.lastPathComponent ?? ""
        }
    }
}

// MARK: - PlaybackStateObservable

extension AudioPlaybackService: PlaybackStateObservable {
    private(set) var currentSource: PlaybackSource? {
        get { currentSourceSubject.value }
        set { currentSourceSubject.send(newValue) }
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

    var currentSourcePublisher: AnyPublisher<PlaybackSource?, Never> {
        currentSourceSubject.eraseToAnyPublisher()
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
}

// MARK: - PlaybackControllable

extension AudioPlaybackService: PlaybackControllable {
    func play(source: PlaybackSource) {
        metadataTask?.cancel()
        metadataTask = nil
        playGeneration += 1
        let generation = playGeneration

        currentSource = source
        title = Self.displayName(for: source)
        artist = nil
        artworkData = nil
        hasPlayedOnceBeforeSubject.send(false)
        artworkResolvedSubject.send(false)
        status = .loading

        startStreamingServerIfNeeded(for: source)
        guard let url = urlResolutionUseCase.url(for: source) else {
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

    func setPlaybackSpeed(_ rate: Float) {
        engine.setPlaybackSpeed(rate)
    }

    func stop() {
        metadataTask?.cancel()
        metadataTask = nil
        playGeneration += 1
        currentSource = nil
        title = ""
        artist = nil
        artworkData = nil
        hasPlayedOnceBeforeSubject.send(false)
        artworkResolvedSubject.send(false)
        status = .loading
        engine.stop()
        streamingRepository.stopServer()
    }
}
