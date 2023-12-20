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

    private var searchingInProgressCount: Int = 0

    // MARK: - Output

    var notifyUpdate: ((any HomeAccountSearchResultViewModelOutputs) -> Void)?

    // MARK: - Components

    private var router: any NodeRouting

    // MARK: - Use Case

    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let searchFileHistoryUseCase: any SearchFileHistoryUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let sdk: MEGASdk
    
    init(
        searchFileUseCase: some SearchFileUseCaseProtocol,
        searchFileHistoryUseCase: some SearchFileHistoryUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        router: some NodeRouting,
        tracker: some AnalyticsTracking,
        sdk: MEGASdk
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.searchFileHistoryUseCase = searchFileHistoryUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.router = router
        self.tracker = tracker
        self.sdk = sdk
    }
}

extension HomeSearchResultViewModel: HomeAccountSearchResultViewModelInputs {

    func didHighlightEmptySearchBar() {
        searchFileUseCase.cancelCurrentSearch()

        let hints = searchFileHistoryUseCase.searchHistoryEntries().map {
            HomeSearchHintViewModel(text: $0.text, searchTime: $0.timeWhenSearchOccur)
        }

        self.notifyUpdate?(HomeSearchViewModel(viewState: .hints(hints)))
    }

    func didInputText(text: String) {
        searchingInProgressCount += 1

        let filter = MEGASearchFilter()
        filter.term = text
        filter.nodeType = Int32(MEGANodeType.unknown.rawValue)
        filter.category = Int32(MEGANodeFormatType.unknown.rawValue)
        filter.sensitivity = false

        searchFileUseCase.searchFiles(
            withFilter: filter,
            recursive: true,
            sortOrder: nil,
            searchPath: .root,
            completion: { [weak self] nodeListEntity in
                guard let self else { return }
                let sdkNodes = nodeListEntity?.toNodeEntities() ?? []

                self.searchFileHistoryUseCase.saveSearchHistoryEntry(
                    SearchFileHistoryEntryDomain(text: text,
                                                 timeWhenSearchOccur: Date()
                                                )
                )

                let searchFilesResult = sdkNodes.map { file in
                    return self.transformeNode(file)
                }

                self.searchingInProgressCount -= 1
                self.triggerUpdate(
                    withNumberOfSearchInProgress: self.searchingInProgressCount,
                    resultFiles: searchFilesResult
                )
            }
        )
    }

    fileprivate func transformeNode(_ file: NodeEntity) -> HomeSearchResultFileViewModel {
        let ownerFolder = self.nodeDetailUseCase.ownerFolder(of: file.handle)
        let imageLoadCompletion: ((@escaping (UIImage?) -> Void) -> Void)? = { [weak self] callback in
            self?.nodeDetailUseCase.loadThumbnail(
                of: file.handle,
                completion: callback
            )
        }

        let moreAction: (HandleEntity, UIButton) -> Void = { _, button in
            self.tracker.trackAnalyticsEvent(with: SearchResultOverflowMenuItemEvent())
            self.router.didTapMoreAction(on: file.handle, button: button)
        }

        return HomeSearchResultFileViewModel(
            handle: file.handle,
            name: file.name,
            folder: ownerFolder?.name ?? "",
            fileType: file.nodeType.debugDescription,
            thumbnail: imageLoadCompletion,
            moreAction: moreAction
        )
    }

    private func triggerUpdate(
        withNumberOfSearchInProgress numberOfSearchInProgress: Int,
        resultFiles: [HomeSearchResultFileViewModel]
    ) {
        asyncOnMain(weakify(self) { strongSelf in
            if numberOfSearchInProgress > 0 {
                strongSelf.notifyUpdate?(HomeSearchViewModel(viewState: .results(.loading)))
            }
            strongSelf.notifyUpdate?(HomeSearchViewModel(viewState: .results(.data(resultFiles))))
        })
    }

    // MARK: - Did Select Node

    func didSelectNode(_ nodeHandle: HandleEntity) {
        router.didTapNode(nodeHandle)
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
}

extension HomeSearchResultViewModel: HomeAccountSearchResultViewModelType {

    var inputs: any HomeAccountSearchResultViewModelInputs { return self }

    struct HomeSearchViewModel: HomeAccountSearchResultViewModelOutputs {
        var viewState: HomeSearchState
    }
}
