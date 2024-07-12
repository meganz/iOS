import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

protocol HomeAccountSearchResultViewModelInputs {
    
    func didHighlightEmptySearchBar()
    
    func didInputText(text: String)
    
    func didSelectNode(_ nodeHandle: HandleEntity)
    
    func didSelectHint(_ hintText: String)
    
    func recalculateExcludeSensitivityOnNextSearch()
}

protocol HomeAccountSearchResultViewModelOutputs {
    
    var viewState: HomeSearchState { get }
}

protocol HomeAccountSearchResultViewModelType {
    
    var inputs: any HomeAccountSearchResultViewModelInputs { get }
    
    var notifyUpdate: ((any HomeAccountSearchResultViewModelOutputs) -> Void)? { get set }
}

final class HomeSearchResultViewModel {
    
    // MARK: - State Variable
    
    private var searchTask: Task<Void, any Error>?
    private var sensitiveTask: Task<Bool, Never>?
    
    // MARK: - Output
    
    var notifyUpdate: ((any HomeAccountSearchResultViewModelOutputs) -> Void)?
    
    // MARK: - Components
    
    private let router: any NodeRouting
    
    // MARK: - Use Case
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let searchFileHistoryUseCase: any SearchFileHistoryUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let sdk: MEGASdk
    private let debounceTimeInNanoseconds: UInt64
    
    init(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        searchFileHistoryUseCase: some SearchFileHistoryUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        router: some NodeRouting,
        tracker: some AnalyticsTracking,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        sdk: MEGASdk,
        debounceTimeInNanoseconds: UInt64 = UInt64(300_000_000)
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.searchFileHistoryUseCase = searchFileHistoryUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.router = router
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
        self.sdk = sdk
        self.debounceTimeInNanoseconds = debounceTimeInNanoseconds
    }
    
    deinit {
        sensitiveTask?.cancel()
        searchTask?.cancel()
    }
    
    @MainActor
    private func notifyUpdateResults(state: HomeSearchResultState) {
        notifyUpdate?(HomeSearchViewModel(viewState: .results(state)))
    }
    
    /// Ensure that exclude sensitivity is only calculated once.
    private func shouldExcludeSensitive() async -> Bool {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
            return false
        }
        if let sensitiveTask {
            return await sensitiveTask.value
        }
        let sensitiveTask = Task { [weak self] in
            guard let self else { return false }
            return await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        }
        self.sensitiveTask = sensitiveTask
        return await sensitiveTask.value
    }
}

extension HomeSearchResultViewModel: HomeAccountSearchResultViewModelInputs {
    
    func didHighlightEmptySearchBar() {
        searchTask?.cancel()
        
        let hints = searchFileHistoryUseCase.searchHistoryEntries().map {
            HomeSearchHintViewModel(text: $0.text, searchTime: $0.timeWhenSearchOccur)
        }
        
        self.notifyUpdate?(HomeSearchViewModel(viewState: .hints(hints)))
    }
    
    func didInputText(text: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            
            try await Task.sleep(nanoseconds: debounceTimeInNanoseconds)
            
            let filter: SearchFilterEntity = .recursive(
                searchText: text,
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: true,
                sortOrderType: .creationAsc,
                formatType: .unknown,
                sensitiveFilterOption: await shouldExcludeSensitive() ? .nonSensitiveOnly : .disabled,
                nodeTypeEntity: .unknown)
            
            let results: [NodeEntity] = try await fileSearchUseCase.search(
                filter: filter, cancelPreviousSearchIfNeeded: true)
            
            try Task.checkCancellation()
            
            searchFileHistoryUseCase.saveSearchHistoryEntry(
                SearchFileHistoryEntryDomain(text: text,
                                             timeWhenSearchOccur: Date()))
            
            let searchFilesResult = results.map(transformNode(_:))
            
            try Task.checkCancellation()
            
            await notifyUpdateResults(state: .data(searchFilesResult))
        }
    }
    
    fileprivate func transformNode(_ file: NodeEntity) -> HomeSearchResultFileViewModel {
        let ownerFolder = self.nodeDetailUseCase.ownerFolder(of: file.handle)

        let moreAction: (HandleEntity, UIButton) -> Void = { [weak self] _, button in
            self?.tracker.trackAnalyticsEvent(with: SearchResultOverflowMenuItemEvent())
            self?.router.didTapMoreAction(on: file.handle, button: button)
        }

        return HomeSearchResultFileViewModel(
            node: file,
            ownerFolder: ownerFolder?.name ?? "",
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            featureFlagProvider: DIContainer.featureFlagProvider,
            moreAction: moreAction)
    }
    
    // MARK: - Did Select Node
    
    func didSelectNode(_ nodeHandle: HandleEntity) {
        router.didTapNode(nodeHandle: nodeHandle)
        if let node = sdk.node(forHandle: nodeHandle) {
            let event = SearchItemSelectedEvent(
                searchItemType: node.isFolder() ? .folder : .file
            )
            tracker.trackAnalyticsEvent(with: event)
        }
        
    }
    
    // MARK: - Hint Search
    
    func didSelectHint(_ hintText: String) {
        didInputText(text: hintText)
        notifyUpdate?(HomeSearchViewModel(viewState: .didSelectHint(hintText)))
    }
    // MARK: - Sensitivity
    
    func recalculateExcludeSensitivityOnNextSearch() {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else { return }
            
        sensitiveTask = nil
    }
}

extension HomeSearchResultViewModel: HomeAccountSearchResultViewModelType {
    
    var inputs: any HomeAccountSearchResultViewModelInputs { return self }
    
    struct HomeSearchViewModel: HomeAccountSearchResultViewModelOutputs {
        var viewState: HomeSearchState
    }
}
