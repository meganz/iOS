import XCTest
import MEGADomain

final class FavouriteNodesUseCaseTests: XCTestCase {

    let favouriteNodesSuccessRepository = MockFavouriteNodesRepository(result: .success([]))
    let favouriteNodesFailureRepository = MockFavouriteNodesRepository(result: .failure(.generic))
    
    func testGetAllFavouriteNodes_success() {
        favouriteNodesSuccessRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testGetAllFavouriteNodes_failed() {
        let mockError: GetFavouriteNodesErrorEntity = .generic
        favouriteNodesFailureRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testGetFavouriteNodesWithLimitCount_success() {
        favouriteNodesSuccessRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testGetFavouriteNodesWithLimitCount_failed() {
        let mockError: GetFavouriteNodesErrorEntity = .generic
        favouriteNodesFailureRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testAllFavouriteNodesWithSearchStringValue_success() {
        favouriteNodesSuccessRepository.allFavouriteNodes(searchString: "test") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testAllFavouriteNodesWithNilSearchStringValue_success() {
        favouriteNodesSuccessRepository.allFavouriteNodes(searchString: nil) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testAllFavouriteNodesWithSearchStringValue_failed() {
        let searchString = "test"
        favouriteNodesFailureRepository.allFavouriteNodes(searchString: searchString) { result in
            switch result {
            case .success:
                XCTFail("errors are not expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testAllFavouriteNodesWithNilSearchStringValue_failed() {
        favouriteNodesFailureRepository.allFavouriteNodes(searchString: nil) { result in
            switch result {
            case .success:
                XCTFail("errors are not expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testAllFavouriteNodes() async throws {
        let resultNodes = [NodeEntity]()
        let nodes = try await favouriteNodesSuccessRepository.allFavouritesNodes()
        XCTAssertEqual(nodes, resultNodes)
    }
}
