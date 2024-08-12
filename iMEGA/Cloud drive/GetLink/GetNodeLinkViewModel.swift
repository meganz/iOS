import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

final class GetNodeLinkViewModel: ViewModelType {
    
    var nodes: [MEGANode] = []
    var invokeCommand: ((GetLinkViewModelCommand) -> Void)?
        
    var link: String = ""
    var separateKey: Bool = false {
        didSet {
            if let nodeType = nodeTypes.first, separateKey {
                getLinkAnalyticsUseCase.sendDecriptionKey(nodeType: nodeType)
            }
        }
    }
    var linkWithoutKey: String {
        if link.contains("file") || link.contains("folder") {
            link.components(separatedBy: "#").first ?? ""
        } else {
            link.components(separatedBy: "!")
                .prefix(2)
                .joined(separator: "!")
        }
    }
    var key: String {
        if link.contains("file") || link.contains("folder") {
            link.components(separatedBy: "#")[safe: 1] ?? ""
        } else {
            link.components(separatedBy: "!")[safe: 2] ?? ""
        }
    }
    var expiryDate: Bool = false
    var date: Date? {
        didSet {
            if let nodeType = nodeTypes.first, date != nil {
                getLinkAnalyticsUseCase.setExpiryDate(nodeType: nodeType)
            }
        }
    }
    var selectDate: Bool = false
    var passwordProtect: Bool = false
    var password: String?
    var isMultiLink: Bool = false
    var nodeTypes: [NodeTypeEntity] = []
    
    private typealias Continuation = AsyncStream<SensitiveContentAcknowledgementStatus>.Continuation
    private let getLinkAnalyticsUseCase = GetLinkAnalyticsUseCase(repository: AnalyticsRepository.newRepo)
    
    private let shareUseCase: any ShareUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private var loadingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    deinit {
        loadingTask?.cancel()
    }

    init(shareUseCase: some ShareUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.shareUseCase = shareUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    func trackSetPassword() {
        guard let nodeType = nodeTypes.first else { return }
        
        if password == nil {
            getLinkAnalyticsUseCase.setPassword(nodeType: nodeType)
        } else {
            getLinkAnalyticsUseCase.resetPassword(nodeType: nodeType)
        }
    }
    
    func trackConfirmPassword() {
        guard let nodeType = nodeTypes.first else { return }
        getLinkAnalyticsUseCase.confirmPassword(nodeType: nodeType)
    }
    func trackRemovePassword() {
        guard let nodeType = nodeTypes.first else { return }
        getLinkAnalyticsUseCase.removePassword(nodeType: nodeType)
    }
        
    func trackProFeatureSeePlans() {
        guard let nodeType = nodeTypes.first else { return }
        getLinkAnalyticsUseCase.proFeatureSeePlans(nodeType: nodeType)
    }
    
    func trackProFeatureNotNow() {
        guard let nodeType = nodeTypes.first else { return }
        getLinkAnalyticsUseCase.proFeatureNotNow(nodeType: nodeType)
    }
    
    func dispatch(_ action: GetLinkAction) {
        switch action {
        case .onViewReady:
            onViewReady()
        case .onViewDidAppear where loadingTask == nil:
            loadingTask = Task { await startGetLinksCoordinatorStream() }
        default:
            break
        }
    }
    
    private func onViewReady() {
        isMultiLink = nodes.count > 1
        nodeTypes = nodes.map { $0.toNodeEntity().nodeType ?? .unknown }
        nodes.notContains { !$0.isExported() } ? trackGetLink() : trackShareLink()
        updateViewConfiguration()
    }
    
    private func trackShareLink() {
        getLinkAnalyticsUseCase.shareLink(nodeTypes: nodeTypes)
    }
    
    private func trackGetLink() {
        getLinkAnalyticsUseCase.getLink(nodeTypes: nodeTypes)
    }
    
    private func updateViewConfiguration() {
        let title = nodes.notContains { !$0.isExported() } ? Strings.Localizable.General.MenuAction.ManageLink.title(nodes.count) :
        Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)
        invokeCommand?(.configureView(title: title,
                                      isMultilink: isMultiLink,
                                      shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)))
    }
        
    @MainActor
    private func startGetLinksCoordinatorStream() async {
        
        let (stream, continuation) = AsyncStream.makeStream(of: SensitiveContentAcknowledgementStatus.self, bufferingPolicy: .bufferingNewest(1))
        
        continuation.yield(featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) ? .unknown : .authorized) // Set initial value

        for await status in stream {
            switch status {
            case .unknown:
                await determineIfContainSensitiveNodes(nodes: nodes, continuation: continuation)
            case .notDetermined:
                showContainsSensitiveContentAlert(continuation: continuation)
            case .noSensitiveContent:
                loadLinksForNodes(continuation: continuation)
            case .authorized:
                invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))
                loadLinksForNodes(continuation: continuation)
            case .denied:
                invokeCommand?(.dismiss)
            }
        }
    }
    
    private func determineIfContainSensitiveNodes(nodes: [MEGANode], continuation: Continuation) async {
        
        let excludeExported = nodes.filter { !$0.isExported() }
                                                   
        guard excludeExported.isNotEmpty else {
            continuation.yield(.authorized)
            return
        }
        
        invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))
        
        do {
            let result = try await shareUseCase.containsSensitiveContent(in: nodes.toNodeEntities())
            continuation.yield(result ? .notDetermined : .noSensitiveContent)
        } catch {
            MEGALogError("[\(type(of: self))]: containsSensitiveContent returned \(error.localizedDescription)")
            continuation.finish()
        }
    }
    
    @MainActor
    private func showContainsSensitiveContentAlert(continuation: Continuation) {
        
        invokeCommand?(.dismissHud)
        let message = if nodes.count > 1 {
            Strings.Localizable.GetNodeLink.Sensitive.Alert.Message.multi
        } else {
            Strings.Localizable.GetNodeLink.Sensitive.Alert.Message.single
        }
        let alertModel = AlertModel(
            title: Strings.Localizable.GetNodeLink.Sensitive.Alert.title,
            message: message,
            actions: [
                .init(title: Strings.Localizable.cancel, style: .cancel, handler: {
                    continuation.yield(.denied)
                }),
                .init(title: Strings.Localizable.continue, style: .default, isPreferredAction: true, handler: {
                    continuation.yield(.authorized)
                })
            ])
        
        invokeCommand?(.showAlert(alertModel))
    }
    
    @MainActor
    private func loadLinksForNodes(continuation: Continuation) {
        
        guard !Task.isCancelled else {
            return
        }
                
        invokeCommand?(.enableLinkActions)
        invokeCommand?(.dismissHud)
        invokeCommand?(.processNodes)
    }
}
