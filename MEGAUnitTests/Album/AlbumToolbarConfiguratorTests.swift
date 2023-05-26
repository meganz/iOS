import XCTest
@testable import MEGA

class AlbumToolbarConfiguratorTest: XCTestCase {
    func testToolbarItems_forGifAndRawAlbumAndIsCreateDisabled_shouldReturnCorrectItems() {
        [AlbumType.gif, .raw].forEach {
            let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                               shareLinkAction: { _ in },
                                               moveAction: { _ in },
                                               copyAction: { _ in },
                                               deleteAction: { _ in },
                                               favouriteAction: { _ in },
                                               removeToRubbishBinAction: { _ in },
                                               exportAction: { _ in },
                                               sendToChatAction: { _ in },
                                               moreAction: { _ in },
                                               albumType: $0,
                                               isCreateAlbumFeatureFlagEnabled: false)
            let buttonItems = sut.toolbarItems(forNodes: nil)
            XCTAssertEqual(buttonItems, [
                sut.downloadItem,
                sut.flexibleItem,
                sut.shareLinkItem,
                sut.flexibleItem,
                sut.moveItem,
                sut.flexibleItem,
                sut.exportItem,
                sut.flexibleItem,
                sut.moreItem
            ])
        }
    }
    
    func testToolbarItems_forFavouriteAlbumIsCreateDisabled_shouldReturnCorrectItems() {
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                           shareLinkAction: { _ in },
                                           moveAction: { _ in },
                                           copyAction: { _ in },
                                           deleteAction: { _ in },
                                           favouriteAction: { _ in },
                                           removeToRubbishBinAction: { _ in },
                                           exportAction: { _ in },
                                           sendToChatAction: { _ in },
                                           moreAction: { _ in },
                                           albumType: .favourite,
                                           isCreateAlbumFeatureFlagEnabled: false)
        let buttonItems = sut.toolbarItems(forNodes: nil)
        XCTAssertEqual(buttonItems, [
            sut.downloadItem,
            sut.flexibleItem,
            sut.shareLinkItem,
            sut.flexibleItem,
            sut.favouriteItem,
            sut.flexibleItem,
            sut.removeToRubbishBinItem,
            sut.flexibleItem,
            sut.moreItem
        ])
    }
    
    func testToolbarItems_forGifAndRawAlbumAndIsCreateEnabled_shouldReturnCorrectItems() {
        [AlbumType.gif, .raw].forEach {
            let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                               shareLinkAction: { _ in },
                                               moveAction: { _ in },
                                               copyAction: { _ in },
                                               deleteAction: { _ in },
                                               favouriteAction: { _ in },
                                               removeToRubbishBinAction: { _ in },
                                               exportAction: { _ in },
                                               sendToChatAction: { _ in },
                                               moreAction: { _ in },
                                               albumType: $0,
                                               isCreateAlbumFeatureFlagEnabled: true)
            let buttonItems = sut.toolbarItems(forNodes: nil)
            XCTAssertEqual(buttonItems, [
                sut.downloadItem,
                sut.flexibleItem,
                sut.shareLinkItem,
                sut.flexibleItem,
                sut.exportItem,
                sut.flexibleItem,
                sut.sendToChatItem
            ])
        }
    }
    
    func testToolbarItems_forFavouriteAlbumIsCreateEnabled_shouldReturnCorrectItems() {
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                           shareLinkAction: { _ in },
                                           moveAction: { _ in },
                                           copyAction: { _ in },
                                           deleteAction: { _ in },
                                           favouriteAction: { _ in },
                                           removeToRubbishBinAction: { _ in },
                                           exportAction: { _ in },
                                           sendToChatAction: { _ in },
                                           moreAction: { _ in },
                                           albumType: .favourite,
                                           isCreateAlbumFeatureFlagEnabled: true)
        let buttonItems = sut.toolbarItems(forNodes: nil)
        XCTAssertEqual(buttonItems, [
            sut.downloadItem,
            sut.flexibleItem,
            sut.shareLinkItem,
            sut.flexibleItem,
            sut.exportItem,
            sut.flexibleItem,
            sut.sendToChatItem,
            sut.flexibleItem,
            sut.favouriteItem
        ])
    }
    
    func testToolbarItems_forUserAlbumIsCreateEnabled_shouldReturnCorrectItems() {
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                           shareLinkAction: { _ in },
                                           moveAction: { _ in },
                                           copyAction: { _ in },
                                           deleteAction: { _ in },
                                           favouriteAction: { _ in },
                                           removeToRubbishBinAction: { _ in },
                                           exportAction: { _ in },
                                           sendToChatAction: { _ in },
                                           moreAction: { _ in },
                                           albumType: .user,
                                           isCreateAlbumFeatureFlagEnabled: true)
        let buttonItems = sut.toolbarItems(forNodes: nil)
        XCTAssertEqual(buttonItems, [
            sut.downloadItem,
            sut.flexibleItem,
            sut.shareLinkItem,
            sut.flexibleItem,
            sut.exportItem,
            sut.flexibleItem,
            sut.sendToChatItem,
            sut.flexibleItem,
            sut.removeToRubbishBinItem
        ])
    }
    
    func testSentToChatButton_onButtonPress_shouldFireSendToChatAction() {
        let exp = expectation(description: "should fire send to chat action")
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in XCTFail("Unexpected action") },
                                           shareLinkAction: { _ in XCTFail("Unexpected action") },
                                           moveAction: { _ in XCTFail("Unexpected action") },
                                           copyAction: { _ in XCTFail("Unexpected action") },
                                           deleteAction: { _ in XCTFail("Unexpected action") },
                                           favouriteAction: { _ in XCTFail("Unexpected action") },
                                           removeToRubbishBinAction: { _ in XCTFail("Unexpected action") },
                                           exportAction: { _ in XCTFail("Unexpected action") },
                                           sendToChatAction: { _ in exp.fulfill() },
                                           moreAction: { _ in XCTFail("Unexpected action") },
                                           albumType: .user,
                                           isCreateAlbumFeatureFlagEnabled: true)
        sut.buttonPressed(sut.sendToChatItem)
        wait(for: [exp], timeout: 1.0)
    }
}
