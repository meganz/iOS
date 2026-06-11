import Combine
import Foundation
import MEGADomain

struct AudioPlaybackState {
    var currentSource: PlaybackSource
    var title: String
    var artist: String?

    /// Raw cover-art bytes parsed from the file's embedded tags (ID3 / MP4).
    /// The presentation layer decodes it to an image.
    var artworkData: Data?

    /// Track duration in seconds, parsed from the asset.
    var duration: TimeInterval?

    /// Coarse playback status the mini player binds to.
    var status: PlaybackStatus = .loading
    var currentTime: TimeInterval = 0

    var currentNode: NodeEntity? { currentSource.primaryNode }
}

enum PlaybackStatus: Equatable {
    case loading
    case playing
    case paused
    case buffering
    case error(String)
}

@MainActor
protocol AudioPlaybackServiceProtocol: AnyObject {
    var statePublisher: AnyPublisher<AudioPlaybackState?, Never> { get }

    func play(source: PlaybackSource)
    func togglePlayPause()
    func seek(toFraction fraction: Double)
    func stop()
}

@MainActor
final class AudioPlaybackService: AudioPlaybackServiceProtocol {
    static let shared = AudioPlaybackService()

    private let stateSubject = CurrentValueSubject<AudioPlaybackState?, Never>(nil)
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

    var statePublisher: AnyPublisher<AudioPlaybackState?, Never> {
        stateSubject.eraseToAnyPublisher()
    }

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
    }

    func play(source: PlaybackSource) {
        metadataTask?.cancel()
        playGeneration += 1
        let generation = playGeneration

        stateSubject.value = AudioPlaybackState(
            currentSource: source,
            title: Self.displayName(for: source),
            status: .loading,
            currentTime: 0
        )
        
        startStreamingServerIfNeeded(for: source)
        guard let url = urlResolutionUseCase.url(for: source) else {
            stateSubject.value?.status = .error("url resolution error")
            return
        }
        metadataTask = Task { [metadataLoader, weak self] in
            guard let self else { return }
            guard let metadata = try? await metadataLoader.loadMetadata(from: url),
                  !metadata.isEmpty,
                  !Task.isCancelled else { return }
            self.applyMetadata(metadata, generation: generation)
        }
        engine.play(url: url)
    }

    private func applyMetadata(_ metadata: AudioMetadata, generation: Int) {
        guard generation == playGeneration, var state = stateSubject.value else { return }
        if let title = metadata.title, !title.isEmpty {
            state.title = title
        }
        state.artist = metadata.artist
        state.artworkData = metadata.artworkData
        state.duration = metadata.duration
        stateSubject.value = state
    }

    func togglePlayPause() {
        engine.togglePlayPause()
    }

    func seek(toFraction fraction: Double) {
        engine.seek(toFraction: fraction)
    }

    func stop() {
        metadataTask?.cancel()
        metadataTask = nil
        playGeneration += 1
        stateSubject.value = nil
        engine.stop()
        streamingRepository.stopServer()
    }

    // MARK: - Private
    private func startStreamingServerIfNeeded(for source: PlaybackSource) {
        if case .offlineFiles = source { return }
        guard !streamingRepository.isServerRunning else { return }
        streamingRepository.startServer()
    }

    private func bindEngineToState() {
        Publishers.CombineLatest3(
            engine.currentTimePublisher,
            engine.durationPublisher,
            engine.playbackStatusPublisher
        )
        .sink { [weak self] currentTime, duration, status in
            self?.mergeEngineState(currentTime: currentTime, duration: duration, status: status)
        }
        .store(in: &cancellables)
    }

    private func mergeEngineState(currentTime: TimeInterval, duration: TimeInterval?, status: PlaybackStatus) {
        guard var current = stateSubject.value else { return }
        current.currentTime = currentTime
        current.duration = duration
        current.status = status
        stateSubject.value = current
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
