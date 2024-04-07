@testable import MEGA
import MEGAPresentation
import MEGAPresentationMock
import XCTest

class AlbumToolbarConfiguratorTest: XCTestCase {
    func testToolbarItems_forGifAndRawAlbum_shouldReturnCorrectItems() {
        [AlbumType.gif, .raw].forEach {
            let sut = makeSUT(albumType: $0)
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
    
    func testToolbarItems_forFavouriteAlbum_shouldReturnCorrectItems() {
        [true, false].forEach { isHiddenNodesEnabled in
            let sut = makeSUT(albumType: .favourite,
                              featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: isHiddenNodesEnabled]))
            
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
                isHiddenNodesEnabled ? sut.moreItem : sut.favouriteItem
            ], "Incorrect button items for hiddenNodesEnabled: \(isHiddenNodesEnabled)")
        }
    }
    
    func testToolbarItems_forUserAlbum_shouldReturnCorrectItems() {
        [true, false].forEach { isHiddenNodesEnabled in
            let sut = makeSUT(albumType: .user,
                              featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: isHiddenNodesEnabled]))
            
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
                isHiddenNodesEnabled ? sut.moreItem : sut.removeToRubbishBinItem
            ], "Incorrect button items for hiddenNodesEnabled: \(isHiddenNodesEnabled)")
        }
    }
    
    func testSentToChatButton_onButtonPress_shouldFireSendToChatAction() {
        let exp = expectation(description: "should fire send to chat action")
        let sut = makeSUT(downloadAction: { _ in XCTFail("Unexpected action") },
                          shareLinkAction: { _ in XCTFail("Unexpected action") },
                          moveAction: { _ in XCTFail("Unexpected action") },
                          copyAction: { _ in XCTFail("Unexpected action") },
                          deleteAction: { _ in XCTFail("Unexpected action") },
                          favouriteAction: { _ in XCTFail("Unexpected action") },
                          removeToRubbishBinAction: { _ in XCTFail("Unexpected action") },
                          exportAction: { _ in XCTFail("Unexpected action") },
                          sendToChatAction: { _ in exp.fulfill() },
                          moreAction: { _ in XCTFail("Unexpected action") },
                          albumType: .user)
        
        sut.buttonPressed(sut.sendToChatItem)
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(
        downloadAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        shareLinkAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        moveAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        copyAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        deleteAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        favouriteAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        removeToRubbishBinAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        exportAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        sendToChatAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        moreAction: @escaping AlbumToolbarConfigurator.ButtonAction = { _ in },
        albumType: AlbumType,
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> AlbumToolbarConfigurator {
        AlbumToolbarConfigurator(
            downloadAction: downloadAction,
            shareLinkAction: shareLinkAction,
            moveAction: moveAction,
            copyAction: copyAction,
            deleteAction: deleteAction,
            favouriteAction: favouriteAction,
            removeToRubbishBinAction: removeToRubbishBinAction,
            exportAction: exportAction,
            sendToChatAction: sendToChatAction,
            moreAction: moreAction,
            albumType: albumType,
            featureFlagProvider: featureFlagProvider)
    }
}
