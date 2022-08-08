import XCTest
@testable import MEGA
import MEGADomain

final class FavouritesViewModelTests: XCTestCase {
    
    let mockFavouritesRouter = MockFavouritesRouter()
    
    func testAction_viewWillAppear() {
        let mockFavouriteNodesUC = MockFavouriteNodesUseCase()
        
        let viewModel = FavouritesViewModel(router: mockFavouritesRouter,
                                            favouritesUseCase: mockFavouriteNodesUC)
        
        mockFavouriteNodesUC.getAllFavouriteNodes { [weak self] result in
            switch result {
            case .success(let nodeEntities):
                self?.test(viewModel: viewModel,
                     action: .viewWillAppear,
                     expectedCommands: [.showFavouritesNodes(nodeEntities)])
                
            case .failure: break
            }
        }
    }
    
    func testAction_viewWillDisappear() {
        let mockFavouritesRouter = MockFavouritesRouter()
        let mockFavouriteNodesUC = MockFavouriteNodesUseCase()
        
        let viewModel = FavouritesViewModel(router: mockFavouritesRouter,
                                            favouritesUseCase: mockFavouriteNodesUC)
        test(viewModel: viewModel,
             action: .viewWillDisappear,
             expectedCommands: [])
    }
    
    func testAction_didSelectRow() {
        let mockFavouritesRouter = MockFavouritesRouter()
        let mockFavouriteNodesUC = MockFavouriteNodesUseCase()
        
        let viewModel = FavouritesViewModel(router: mockFavouritesRouter,
                                            favouritesUseCase: mockFavouriteNodesUC)
        
        let mockNodeModel = NodeEntity()
        test(viewModel: viewModel,
             action: .didSelectRow(mockNodeModel.handle),
             expectedCommands: [])
        XCTAssertEqual(mockFavouritesRouter.openNode_calledTimes, 1)
    }
}
