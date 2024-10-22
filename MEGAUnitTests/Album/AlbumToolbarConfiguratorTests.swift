@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

class AlbumToolbarConfiguratorTest: XCTestCase {
    func testToolbarItems_forGifAndRawAlbum_shouldReturnCorrectItems() {
        [AlbumType.gif, .raw].forEach { albumType in
            [true, false].forEach { isHiddenNodesEnabled in
                let sut = makeSUT(albumType: albumType,
                                  remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: isHiddenNodesEnabled]))
                
                let buttonItems = sut.toolbarItems(forNodes: nil)
                
                var expectedButtonItems = [
                    sut.downloadItem,
                    sut.flexibleItem,
                    sut.shareLinkItem,
                    sut.flexibleItem,
                    sut.exportItem,
                    sut.flexibleItem,
                    sut.sendToChatItem
                ]
                if isHiddenNodesEnabled {
                    expectedButtonItems.append(contentsOf: [
                        sut.flexibleItem,
                        sut.moreItem
                    ])
                }
                
                XCTAssertEqual(buttonItems, expectedButtonItems,
                               "Incorrect button items for hiddenNodesEnabled: \(isHiddenNodesEnabled) album type \(albumType)")
            }
        }
    }
    
    func testToolbarItems_forFavouriteAlbum_shouldReturnCorrectItems() {
        [true, false].forEach { isHiddenNodesEnabled in
            let sut = makeSUT(albumType: .favourite,
                              remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: isHiddenNodesEnabled]))
            
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
                              remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: isHiddenNodesEnabled]))
            
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
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase()
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
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
    }
}
