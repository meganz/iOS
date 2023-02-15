import Foundation
import Combine
import MEGADomain
import MEGAFoundation
import MEGAPresentation

enum MediaDiscoveryAction: ActionType {
    case onViewReady
    case onViewDidAppear
    case onViewWillDisAppear
}

final class MediaDiscoveryViewModel: NSObject, ViewModelType, NodesUpdateProtocol {
    enum Command: Equatable, CommandType {
        case loadMedia(nodes: [NodeEntity])
    }
    
    private let parentNode: NodeEntity
    private var nodes: [NodeEntity] = []
    private let router: MediaDiscoveryRouter
    private let analyticsUseCase: MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: MediaDiscoveryUseCaseProtocol
    
    private var loadingTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    var invokeCommand: ((Command) -> Void)?
    
    lazy var pageStayTimeTracker = PageStayTimeTracker()
    
    // MARK: - Init
    
    init(parentNode: NodeEntity, router: MediaDiscoveryRouter,
         analyticsUseCase: MediaDiscoveryAnalyticsUseCaseProtocol,
         mediaDiscoveryUseCase: MediaDiscoveryUseCaseProtocol) {
        self.parentNode = parentNode
        self.router = router
        self.analyticsUseCase = analyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        
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
}
