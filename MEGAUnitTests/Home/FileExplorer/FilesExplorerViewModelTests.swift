@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class FilesExplorerViewModelTests: XCTestCase {
    
    func testActionStartSearching_ForAllDocsAndAudio_shouldReturnNodes() {
        for featureFlagActive in [true, false] {
            for explorerType in [ExplorerTypeEntity.allDocs, .audio] {
                
                let expectedNodes = [
                    MockNode(handle: 1, name: "1", parentHandle: 0),
                    MockNode(handle: 2, name: "2", parentHandle: 0),
                    MockNode(handle: 3, name: "3", parentHandle: 0)
                ]
                let filesSearchUseCase = MockFilesSearchUseCase(searchResult: .success(expectedNodes.toNodeEntities()))
                
                let searchText: String? = "test"
                let sut = sut(
                    explorerType: explorerType,
                    filesSearchUseCase: filesSearchUseCase,
                    nodeProvider: MockMEGANodeProvider(nodes: expectedNodes),
                    featureFlagHiddenNodes: featureFlagActive)
                
                test(viewModel: sut, action: .startSearching(searchText), expectedCommands: [.reloadNodes(nodes: expectedNodes, searchText: searchText)], expectationValidation: isEquals)
                XCTAssertEqual(filesSearchUseCase.messages, [.onNodesUpdate] + [featureFlagActive ? .search : .searchLegacy])
            }
        }
    }
    
    func testActionStartSearching_ForFavourites_shouldReturnNodes() {
        
        let expectedNodes = [
            MockNode(handle: 1, name: "1", parentHandle: 0),
            MockNode(handle: 2, name: "2", parentHandle: 0),
            MockNode(handle: 3, name: "3", parentHandle: 0)
        ]
        
        let searchText: String? = "test"
        let sut = sut(
            explorerType: .favourites,
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(expectedNodes.toNodeEntities())),
            nodeProvider: MockMEGANodeProvider(nodes: expectedNodes))
        
        test(viewModel: sut, action: .startSearching(searchText), expectedCommands: [.reloadNodes(nodes: expectedNodes, searchText: searchText)], expectationValidation: isEquals)
    }
}

private extension FilesExplorerViewModelTests {
    func sut(
        explorerType: ExplorerTypeEntity,
        filesSearchUseCase: some FilesSearchUseCaseProtocol = MockFilesSearchUseCase(searchResult: .success([])),
        favouritesUseCase: some FavouriteNodesUseCaseProtocol = MockFavouriteNodesUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        nodeProvider: some MEGANodeProviderProtocol = MockMEGANodeProvider(),
        featureFlagHiddenNodes: Bool = false) -> FilesExplorerViewModel {
            let sdk = MockSdk()
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: featureFlagHiddenNodes])
            return .init(
                explorerType: explorerType,
                router: FilesExplorerRouter(navigationController: nil, explorerType: explorerType, featureFlagProvider: featureFlagProvider),
                useCase: filesSearchUseCase,
                favouritesUseCase: favouritesUseCase,
                filesDownloadUseCase: FilesDownloadUseCase(repo: .init(sdk: sdk)),
                nodeClipboardOperationUseCase: NodeClipboardOperationUseCase(repo: .init(sdk: sdk)),
                contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                createContextMenuUseCase: MockCreateContextMenuUseCase(),
                nodeProvider: nodeProvider,
                featureFlagProvider: featureFlagProvider)
        }
    
    func isEquals(lhs: FilesExplorerViewModel.Command, rhs: FilesExplorerViewModel.Command) -> Bool {
        let conditions: [Bool] = switch (lhs, rhs) {
        case let (.reloadNodes(lhsNodes, lhsSearchText), .reloadNodes(rhsNodes, rhsSearchText)):
            [lhsNodes == rhsNodes, lhsSearchText == rhsSearchText]
        default:
            [false]
        }
        return conditions.allSatisfy { $0 }
    }
}
