import Foundation

protocol HomeAccountSearchResultViewModelInputs {

    func didHilightEmptySearchBar()

    func didInputText(text: String)

    func didSelectNode(_ nodeHandle: HandleEntity)

    func didSelectHint(_ hintText: String)
}

protocol HomeAccountSearchResultViewModelOutputs {

    var viewState: HomeSearchState { get }
}

protocol HomeAccountSearchResultViewModelType {

    var inputs: HomeAccountSearchResultViewModelInputs { get }

    var notifyUpdate: ((HomeAccountSearchResultViewModelOutputs) -> Void)? { get set }
}

final class HomeSearchResultViewModel {

    // MARK: - State Variable

    private var searchingInProgressCount: Int = 0

    // MARK: - Output

    var notifyUpdate: ((HomeAccountSearchResultViewModelOutputs) -> Void)?

    // MARK: - Components

    private var router: HomeSearchResultRouter

    // MARK: - Use Case

    private let searchFileUseCase: SearchFileUseCaseProtocol
    private let searchFileHistoryUseCase: SearchFileHistoryUseCaseProtocol
    private let nodeDetailUseCase: NodeDetailUseCaseProtocol

    init(
        searchFileUseCase: SearchFileUseCaseProtocol,
        searchFileHistoryUseCase: SearchFileHistoryUseCaseProtocol,
        nodeDetailUseCase: NodeDetailUseCaseProtocol,
        router: HomeSearchResultRouter
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.searchFileHistoryUseCase = searchFileHistoryUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.router = router
    }
}

extension HomeSearchResultViewModel: HomeAccountSearchResultViewModelInputs {

    func didHilightEmptySearchBar() {
        searchFileUseCase.cancelCurrentSearch()

        let hints = searchFileHistoryUseCase.searchHistoryEntries().map {
            HomeSearchHintViewModel(text: $0.text, searchTime: $0.timeWhenSearchOccur)
        }

        self.notifyUpdate?(HomeSearchViewModel(viewState: .hints(hints)))
    }

    func didInputText(text: String) {
        let trimmedSearchText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        searchingInProgressCount += 1
        searchFileUseCase.searchFiles(withName: trimmedSearchText, searchPath: .root) { [weak self] sdkNodes in
            guard let self = self else { return }

            self.searchFileHistoryUseCase.saveSearchHistoryEntry(
                SearchFileHistoryEntryDomain(text: trimmedSearchText,
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
    }

    fileprivate func transformeNode(_ file: NodeEntity) -> HomeSearchResultFileViewModel {
        let ownerFolder = self.nodeDetailUseCase.ownerFolder(of: file.handle)
        let imageLoadCompletion: ((@escaping (UIImage?) -> Void) -> Void)? = { [weak self] callback in
            self?.nodeDetailUseCase.loadThumbnail(
                of: file.handle,
                completion: callback
            )
        }

        let moreAction: (HandleEntity, UIButton) -> Void = { handle, button in
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
    }

    // MARK: - Hint Search

    func didSelectHint(_ hintText: String) {
        didInputText(text: hintText)
        notifyUpdate?(HomeSearchViewModel(viewState: .didSelectHint(hintText)))
    }
}

extension HomeSearchResultViewModel: HomeAccountSearchResultViewModelType {

    var inputs: HomeAccountSearchResultViewModelInputs { return self }

    struct HomeSearchViewModel: HomeAccountSearchResultViewModelOutputs {
        var viewState: HomeSearchState
    }
}
