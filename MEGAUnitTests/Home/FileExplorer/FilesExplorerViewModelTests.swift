@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class FilesExplorerViewModelTests: XCTestCase {
    
    func testActionStartSearching_ForAllExploreTypes_shouldReturnNodes() {
        // Ensure sort order is set during test
        Helper.save(.defaultDesc, for: nil)
        
        for featureFlagActive in [true, false] {
            for explorerType in [ExplorerTypeEntity.allDocs, .audio, .favourites] {
                
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
                XCTAssertEqual(filesSearchUseCase.messages, [.onNodesUpdate, .search])
                XCTAssertEqual(filesSearchUseCase.filters, expectedSearchFilters(for: explorerType, searchText: searchText, excludeSensitive: featureFlagActive))
            }
        }
    }
}

private extension FilesExplorerViewModelTests {
    func expectedSearchFilters(for explorerType: ExplorerTypeEntity, searchText: String?, excludeSensitive: Bool) -> [SearchFilterEntity] {
        let nodeFormatType: NodeFormatEntity = switch explorerType {
        case .allDocs: .allDocs
        case .audio: .audio
        case .video: .video
        case .favourites: .unknown
        }
        
        let sensitiveFilterOption = excludeSensitive ? SearchFilterEntity.SensitiveFilterOption.nonSensitiveOnly : .disabled
        
        return switch explorerType {
        case .audio, .allDocs:
            [
                .init(searchText: searchText, searchTargetLocation: .folderTarget(.rootNode), recursive: true, supportCancel: true, sortOrderType: .defaultDesc, formatType: nodeFormatType, sensitiveFilterOption: sensitiveFilterOption, favouriteFilterOption: .disabled)
            ]
        case .favourites:
            [
                .init(searchText: searchText, searchTargetLocation: .folderTarget(.rootNode), recursive: true, supportCancel: true, sortOrderType: .defaultDesc, formatType: nodeFormatType, sensitiveFilterOption: sensitiveFilterOption, favouriteFilterOption: .onlyFavourites)
            ]
        default:
            []
        }
    }
    
    func sut(
        explorerType: ExplorerTypeEntity,
        filesSearchUseCase: some FilesSearchUseCaseProtocol = MockFilesSearchUseCase(searchResult: .success([])),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        nodeProvider: some MEGANodeProviderProtocol = MockMEGANodeProvider(),
        featureFlagHiddenNodes: Bool = false) -> FilesExplorerViewModel {
            let sdk = MockSdk()
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: featureFlagHiddenNodes])
            return .init(
                explorerType: explorerType,
                router: FilesExplorerRouter(navigationController: nil, explorerType: explorerType, featureFlagProvider: featureFlagProvider),
                useCase: filesSearchUseCase,
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
