@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepo
import MEGASDKRepoMock
import MEGATest
import UIKit
import XCTest

final class HomeSearchResultViewModelTests: XCTestCase {
    func testDidInputText_onMultipleInputText_shouldOnlyUseLastEntryAndUseCorrectFilters() {
        let nodes = [NodeEntity(handle: 1), NodeEntity(handle: 2), NodeEntity(handle: 3)]
        let filesSearchUseCase = MockFilesSearchUseCase(searchResult: .success(nodes))
        let searchFileHistoryUseCase = MockSearchFileHistoryUseCase()
        let sut = makeSUT(fileSearchUseCase: filesSearchUseCase,
                          searchFileHistoryUseCase: searchFileHistoryUseCase)
        
        let exp = expectSearchResult(on: sut, expectedNodes: nodes)
        let lastInputText = "png"
        
        sut.didInputText(text: "p")
        sut.didInputText(text: "pn")
        sut.didInputText(text: lastInputText)
        
        wait(for: [exp], timeout: 1.0)
        
        let expectedFilter = makeSearchFilter(inputText: lastInputText,
                                              excludeSensitive: false)
        
        XCTAssertEqual(filesSearchUseCase.filters, [expectedFilter])
        XCTAssertEqual(searchFileHistoryUseCase.savedHistoryEntries.map(\.text),
                       [lastInputText])
    }
    
    func testDidInputText_onSensitiveSearch_shouldOnlyUseLastEntryAndUseCorrectFilters() {
        let nodes = [NodeEntity(handle: 1), NodeEntity(handle: 2), NodeEntity(handle: 3)]
        let showHiddenNodes = false
        let filesSearchUseCase = MockFilesSearchUseCase(searchResult: .success(nodes))
        let searchFileHistoryUseCase = MockSearchFileHistoryUseCase()
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: showHiddenNodes))
        
        let sut = makeSUT(fileSearchUseCase: filesSearchUseCase,
                          searchFileHistoryUseCase: searchFileHistoryUseCase,
                          contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let exp = expectSearchResult(on: sut, expectedNodes: nodes)
        
        let inputText = "png"
        sut.didInputText(text: inputText)
        
        wait(for: [exp], timeout: 1.0)
        
        let expectedFilter = makeSearchFilter(inputText: inputText,
                                              excludeSensitive: !showHiddenNodes)
        
        XCTAssertEqual(filesSearchUseCase.filters, [expectedFilter])
        XCTAssertEqual(searchFileHistoryUseCase.savedHistoryEntries.map(\.text),
                       [inputText])
    }
    
    func testRecalculateExcludeSensitivityOnNextSearch_afterSearched_shouldUseCorrectFilterOnNextSearch() async throws {
        let nodes = [NodeEntity(handle: 1), NodeEntity(handle: 2), NodeEntity(handle: 3)]
        let showHiddenNodes = false
        let filesSearchUseCase = MockFilesSearchUseCase(searchResult: .success(nodes))
        let searchFileHistoryUseCase = MockSearchFileHistoryUseCase()
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: showHiddenNodes))
        
        let sut = makeSUT(fileSearchUseCase: filesSearchUseCase,
                          searchFileHistoryUseCase: searchFileHistoryUseCase,
                          contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let firstSearchExp = expectSearchResult(on: sut, expectedNodes: nodes)
        
        let inputText = "png"
        sut.didInputText(text: inputText)
        
        await fulfillment(of: [firstSearchExp], timeout: 1.0)
        
        try await contentConsumptionUserAttributeUseCase.saveSensitiveSetting(showHiddenNodes: !showHiddenNodes)
        
        sut.recalculateExcludeSensitivityOnNextSearch()
        
        let secondSearchExp = expectSearchResult(on: sut, expectedNodes: nodes)
        
        sut.didInputText(text: inputText)
        
        await fulfillment(of: [secondSearchExp], timeout: 1.0)
        
        let expectedFilters =  [makeSearchFilter(inputText: inputText,
                                                 excludeSensitive: !showHiddenNodes),
                                makeSearchFilter(inputText: inputText,
                                                 excludeSensitive: showHiddenNodes)
        ]
        
        XCTAssertEqual(filesSearchUseCase.filters, expectedFilters)
        XCTAssertEqual(searchFileHistoryUseCase.savedHistoryEntries.map(\.text),
                       [inputText, inputText])
    }

    @MainActor
    func testIsFromSharedItem_whenMoreActionInvoked_shouldReturnFalseForIsFromSharedItem() async {
        let router = MockNodeRouting()
        let nodes = [NodeEntity(handle: 1), NodeEntity(handle: 2), NodeEntity(handle: 3)]
        let filesSearchUseCase = MockFilesSearchUseCase(searchResult: .success(nodes))
        let searchFileHistoryUseCase = MockSearchFileHistoryUseCase()
        let sut = makeSUT(
            fileSearchUseCase: filesSearchUseCase,
            searchFileHistoryUseCase: searchFileHistoryUseCase,
            router: router
        )

        let exp = expectation(description: "Should update with results")

        sut.notifyUpdate = { [weak exp] in
            if case let .results(resultState) = $0.viewState {
                switch resultState {
                case .data(let viewModels):
                    viewModels.first?.moreAction(.invalid, UIButton())
                    exp?.fulfill()
                default:
                    XCTFail("Invalid result state emitted")
                }
            }
        }

        sut.didInputText(text: "p")
        await fulfillment(of: [exp], timeout: 1.0)
        guard case let .didTapMoreActionWithoutDisplayMode(_, _, isFromSharedItem) = router.actions.first else {
            XCTFail("Expected didTapMoreActionWithoutDisplayMode")
            return
        }

        XCTAssertFalse(isFromSharedItem)
    }

    private func makeSUT(
        fileSearchUseCase: some FilesSearchUseCaseProtocol = MockFilesSearchUseCase(),
        searchFileHistoryUseCase: some SearchFileHistoryUseCaseProtocol = MockSearchFileHistoryUseCase(),
        nodeDetailUseCase: some NodeDetailUseCaseProtocol = MockNodeDetailUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        router: some NodeRouting = MockNodeRouting(),
        tracker: some AnalyticsTracking = MockTracker(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        sdk: MEGASdk = MockSdk(),
        debounceTimeInNanoseconds: UInt64 = UInt64(100_000_000),
        file: StaticString = #file,
        line: UInt = #line
    ) -> HomeSearchResultViewModel {
        let sut = HomeSearchResultViewModel(
            fileSearchUseCase: fileSearchUseCase,
            searchFileHistoryUseCase: searchFileHistoryUseCase,
            nodeDetailUseCase: nodeDetailUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            router: router,
            tracker: tracker,
            featureFlagProvider: featureFlagProvider,
            sdk: sdk,
            debounceTimeInNanoseconds: debounceTimeInNanoseconds)
        addTeardownBlock { [weak sut] in
            try await Task.sleep(nanoseconds: debounceTimeInNanoseconds + 50_000_000)
            
            XCTAssertNil(sut, "[\(type(of: self))] should have been deallocated, potential memory leak.", file: file, line: line)
        }
        return sut
    }
    
    private func expectSearchResult(on sut: HomeSearchResultViewModel, expectedNodes: [NodeEntity]) -> XCTestExpectation {
        let exp = expectation(description: "Should update with results")
        
        sut.notifyUpdate = { [weak exp] in
            if case let .results(resultState) = $0.viewState {
                switch resultState {
                case .data(let viewModels):
                    XCTAssertEqual(viewModels.map(\.handle), expectedNodes.map(\.handle))
                    exp?.fulfill()
                default:
                    XCTFail("Invalid result state emitted")
                }
            }
        }
        return exp
    }
    
    private func makeSearchFilter(inputText: String, excludeSensitive: Bool) -> SearchFilterEntity {
        .recursive(
            searchText: inputText,
            searchTargetLocation: .folderTarget(.rootNode),
            supportCancel: true,
            sortOrderType: .creationAsc,
            formatType: .unknown,
            sensitiveFilterOption: excludeSensitive ? .nonSensitiveOnly : .disabled,
            nodeTypeEntity: .unknown)
    }
}

private final class MockNodeRouting: NodeRouting {
    enum Actions: Equatable {
        case didTapMoreActionWithoutDisplayMode(HandleEntity, UIButton, Bool)
        case didTapMoreActionWithDisplayMode(HandleEntity, UIButton, DisplayMode?, Bool)
    }

    private(set) var actions: [Actions] = []

    func didTapMoreAction(on node: HandleEntity, button: UIButton, isFromSharedItem: Bool) {
        actions.append(.didTapMoreActionWithoutDisplayMode(node, button, isFromSharedItem))
    }
    
    func didTapMoreAction(on node: HandleEntity, button: UIButton, displayMode: DisplayMode?, isFromSharedItem: Bool) {
        actions.append(.didTapMoreActionWithDisplayMode(node, button, displayMode, isFromSharedItem))
    }
    
    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?, displayMode: DisplayMode?, isFromSharedItem: Bool, warningViewModel: WarningViewModel?) {
        
    }
    
    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?) {
        
    }
    
    func didTapNode(nodeHandle: HandleEntity) {
        
    }
}

private final class MockSearchFileHistoryUseCase: SearchFileHistoryUseCaseProtocol {
    private let _searchHistoryEntries: [SearchFileHistoryEntryDomain]
    
    private(set) var savedHistoryEntries = [SearchFileHistoryEntryDomain]()
    
    init(searchHistoryEntries: [SearchFileHistoryEntryDomain] = []) {
        _searchHistoryEntries = searchHistoryEntries
    }
    
    func searchHistoryEntries() -> [SearchFileHistoryEntryDomain] {
        _searchHistoryEntries
    }
    
    func saveSearchHistoryEntry(_ entry: SearchFileHistoryEntryDomain) {
        savedHistoryEntries.append(entry)
    }
    
    func clearSearchHistoryEntries() {
        
    }
}
