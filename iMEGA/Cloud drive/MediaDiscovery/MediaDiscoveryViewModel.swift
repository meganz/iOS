import Foundation
import Combine
import MEGADomain
import MEGAFoundation
import MEGAPresentation

enum MediaDiscoveryAction: ActionType {
    case onViewReady
    case onViewDidAppear
    case onViewWillDisAppear
    case downloadSelectedPhotos([NodeEntity])
    case saveToPhotos([NodeEntity])
    case importPhotos([NodeEntity])
    case shareLink(UIBarButtonItem?)
}

final class MediaDiscoveryViewModel: NSObject, ViewModelType, NodesUpdateProtocol {
    enum Command: Equatable, CommandType {
        case loadMedia(nodes: [NodeEntity])
        case showSaveToPhotosError(String)
        case endEditingMode
    }
    
    private let parentNode: NodeEntity
    private var nodes: [NodeEntity] = []
    private let router: MediaDiscoveryRouting
    private let analyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private let saveMediaUseCase: any SaveMediaToPhotosUseCaseProtocol
    
    private var loadingTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    var invokeCommand: ((Command) -> Void)?
    
    lazy var pageStayTimeTracker = PageStayTimeTracker()
    
    // MARK: - Init
    
    init(parentNode: NodeEntity,
         folderLink: String? = nil,
         router: MediaDiscoveryRouting,
         analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol,
         mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol,
         saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol) {
        self.parentNode = parentNode
        self.router = router
        self.analyticsUseCase = analyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        self.saveMediaUseCase = saveMediaUseCase
        
        super.init()
        initSubscriptions()
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: MediaDiscoveryAction) {
        switch action {
        case .onViewReady:
            sendPageVisitedStats()
            loadNodes()
        case .onViewDidAppear:
            startTracking()
        case .onViewWillDisAppear:
            endTracking()
            sendPageStayStats()
            cancelLoading()
        case .downloadSelectedPhotos(let photos):
            downloadSelectedPhotos(photos)
        case .saveToPhotos(let photos):
            saveToPhotos(photos)
        case .importPhotos(let photos):
            importPhotos(photos)
        case .shareLink(let sender):
            invokeCommand?(.endEditingMode)
            router.showShareLink(sender: sender)
        }
    }
    
    // MARK: Private
    
    private func initSubscriptions() {
        mediaDiscoveryUseCase.nodeUpdatesPublisher
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .sink { [weak self] updatedNodes in
                guard let self else { return }
                if self.mediaDiscoveryUseCase.shouldReload(parentNode: self.parentNode, loadedNodes: self.nodes, updatedNodes: updatedNodes) {
                    self.loadNodes()
                }
            }.store(in: &subscriptions)
    }
    
    private func loadNodes() {
        loadingTask = Task { @MainActor in
            do {
                nodes = try await mediaDiscoveryUseCase.nodes(forParent: parentNode)
                invokeCommand?(.loadMedia(nodes: nodes))
            } catch {
                MEGALogError("Error loading nodes: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelLoading() {
        loadingTask?.cancel()
        subscriptions.removeAll()
    }
    
    private func startTracking() {
        pageStayTimeTracker.start()
    }
    
    private func endTracking() {
        pageStayTimeTracker.end()
    }
    
    private func sendPageVisitedStats() {
        analyticsUseCase.sendPageVisitedStats()
    }
    
    private func sendPageStayStats() {
        let duration = Int(pageStayTimeTracker.duration)
        
        analyticsUseCase.sendPageStayStats(with: duration)
    }
    
    private func downloadSelectedPhotos(_ photos: [NodeEntity]) {
        guard photos.isNotEmpty else { return }
        invokeCommand?(.endEditingMode)
        router.showDownload(photos: photos)
    }
    
    private func saveToPhotos(_ photos: [NodeEntity]) {
        guard photos.isNotEmpty else { return }
        invokeCommand?(.endEditingMode)
        Task { @MainActor in
            do {
                try await saveMediaUseCase.saveToPhotos(nodes: photos)
            } catch let error as SaveMediaToPhotosErrorEntity {
                if error != .cancelled {
                    invokeCommand?(.showSaveToPhotosError(error.localizedDescription))
                }
            } catch {
                MEGALogError("Error saving photos: \(error.localizedDescription)")
            }
        }
    }
    
    private func importPhotos(_ photos: [NodeEntity]) {
        guard photos.isNotEmpty else { return }
        invokeCommand?(.endEditingMode)
        router.showImportLocation(photos: photos)
    }
}
