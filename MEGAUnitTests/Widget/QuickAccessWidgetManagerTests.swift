@testable import MEGA
import MEGADomain
import MEGASDKRepoMock
import XCTest

final class QuickAccessWidgetManagerTests: XCTestCase {
    func testQuickAccessWidgetManager_updateFavoritesCalledWithFavouriteChange_shouldCallFavouriteItemsUseCaseInsertFavouriteItem() {
        let sut = QuickAccessWidgetManager(favouriteItemsUseCase: MockFavouriteItemsUseCase())

        let mockNodes: [MockNode] = [
            .init(handle: 1, name: "first", changeType: .favourite, isFavourite: true),
            .init(handle: 2, name: "second", changeType: .favourite, isFavourite: false)
        ]

        let mockNodeList = MockNodeList(nodes: mockNodes)

        sut.updateFavouritesWidget(for: mockNodeList)
    }
}

private extension QuickAccessWidgetManagerTests {
    struct MockFavouriteItemsUseCase: FavouriteItemsUseCaseProtocol {
        func insertFavouriteItem(_ item: MEGADomain.FavouriteItemEntity) {
            XCTAssertEqual(item.base64Handle, "1")
            XCTAssertEqual(item.name, "first")
        }

        func deleteFavouriteItem(with base64Handle: MEGADomain.Base64HandleEntity) {
            XCTAssertEqual("2", base64Handle)
        }

        func createFavouriteItems(_ items: [MEGADomain.FavouriteItemEntity], completion: @escaping (Result<Void, MEGADomain.GetFavouriteNodesErrorEntity>) -> Void) {
            // no-op
        }

        func batchInsertFavouriteItems(_ items: [MEGADomain.FavouriteItemEntity], completion: @escaping (Result<Void, MEGADomain.GetFavouriteNodesErrorEntity>) -> Void) {
            // no-op
        }

        func fetchAllFavouriteItems() -> [MEGADomain.FavouriteItemEntity] {
            []
        }

        func fetchFavouriteItems(upTo count: Int) -> [MEGADomain.FavouriteItemEntity] {
            []
        }
    }
}
