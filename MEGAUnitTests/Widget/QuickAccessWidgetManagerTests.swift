@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

final class QuickAccessWidgetManagerTests: XCTestCase {
    
    func testQuickAccessWidgetManager_nodeUpdateContainsFavouriteChanges_shouldCallCreateFavouriteItems() async {
        
        let expectedScenario: [(MEGANodeChangeType, Bool)] = [
            (.removed, true),
            (.attributes, false),
            (.owner, false),
            (.timestamp, false),
            (.fileAttributes, false),
            (.inShare, false),
            (.outShare, false),
            (.parent, false),
            (.pendingShare, false),
            (.publicLink, false),
            (.new, true),
            (.name, true),
            (.favourite, true),
            (.sensitive, true)
        ]
    
        for (changeType, expectedResult) in expectedScenario {
            let favouriteItemsUseCase = MockFavouriteItemsUseCase()
            let sut = sut(
                favouriteItemsUseCase: favouriteItemsUseCase
            )

            let mockNodes: [MockNode] = [
                .init(handle: 1, name: "first", changeType: changeType, isFavourite: true)
            ]
            
            let expectingResultScenario = { [weak self] (changeType: MEGANodeChangeType, favouriteItemsUseCase: MockFavouriteItemsUseCase) in
                guard let self else {
                    XCTFail("Self has been deallocated")
                    return
                }
                let expectation = expectation(description: "Expecting event to occur for changeType (\(changeType)")

                let task = await expectationTaskStarted {
                    for await events in favouriteItemsUseCase.eventsStream {
                        XCTAssertEqual(events, .createFavouriteItems([]))
                        expectation.fulfill()
                        break
                    }
                }
                sut.updateWidgetContent(with: MockNodeList(nodes: mockNodes))
                await fulfillment(of: [expectation], timeout: 1)
                task.cancel()
            }
            
            let notExpectingResultScenario = { [weak self] (changeType: MEGANodeChangeType, favouriteItemsUseCase: MockFavouriteItemsUseCase) in
                guard let self else {
                    XCTFail("Self has been deallocated")
                    return
                }
                let expectation = expectation(description: "Not expecting any events to occur for changeType (\(changeType)")
                expectation.isInverted = true
                let task = await expectationTaskStarted {
                    for await _ in favouriteItemsUseCase.eventsStream {
                        expectation.fulfill()
                        break
                    }
                }
                sut.updateWidgetContent(with: MockNodeList(nodes: mockNodes))
                await fulfillment(of: [expectation], timeout: 1)
                task.cancel()
            }
                        
            if expectedResult {
                await expectingResultScenario(changeType, favouriteItemsUseCase)
            } else {
                await notExpectingResultScenario(changeType, favouriteItemsUseCase)
            }
        }
    }
    
    func testQuickAccessWidgetManager_nodeUpdateContainsRecentsChangesAndIsAFolder_noChangesShouldOccur() async {
        
        let recentItemsUseCase = MockRecentItemsUseCase()
        let sut = sut(
            recentItemsUseCase: recentItemsUseCase
        )
        
        let mockNodes: [MockNode] = [
            .init(handle: 1, name: "first", nodeType: .folder, changeType: .attributes, isFavourite: true)
        ]
        
        sut.updateWidgetContent(with: MockNodeList(nodes: mockNodes))
        
        let expectation = expectation(description: "Not expecting any events to occur for folders")
        expectation.isInverted = true
        trackTaskCancellation {
            for await _ in recentItemsUseCase.eventsStream {
                expectation.fulfill()
                break
            }
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testQuickAccessWidgetManager_nodeUpdateContainsRecentsChanges_shouldCallCreateRecentsItems() async {
        
        let expectedScenario: [(MEGANodeChangeType, Bool)] = [
            (.removed, true),
            (.attributes, false),
            (.owner, false),
            (.timestamp, false),
            (.fileAttributes, false),
            (.inShare, false),
            (.outShare, false),
            (.parent, false),
            (.pendingShare, false),
            (.publicLink, false),
            (.new, true),
            (.name, true),
            (.favourite, false),
            (.sensitive, true)
        ]
        
        for (changeType, expectedResult) in expectedScenario {
            let recentItemsUseCase = MockRecentItemsUseCase()
            let sut = sut(
                recentItemsUseCase: recentItemsUseCase
            )

            let mockNodes: [MockNode] = [
                .init(handle: 1, name: "first", changeType: changeType, isFavourite: true)
            ]
            
            let expectingResultScenario = { [weak self] (changeType: MEGANodeChangeType, recentItemsUseCase: MockRecentItemsUseCase) in
                guard let self else {
                    XCTFail("Self has been deallocated")
                    return
                }
                let expectation = expectation(description: "Expecting event to occur for changeType (\(changeType)")
                let task = await expectationTaskStarted {
                    for await events in recentItemsUseCase.eventsStream {
                        XCTAssertEqual(events, .resetRecentItems([]))
                        expectation.fulfill()
                        break
                    }
                }
                sut.updateWidgetContent(with: MockNodeList(nodes: mockNodes))
                await fulfillment(of: [expectation], timeout: 1)
                task.cancel()
            }
            
            let notExpectingResultScenario = { [weak self] (changeType: MEGANodeChangeType, recentItemsUseCase: MockRecentItemsUseCase) in
                guard let self else {
                    XCTFail("Self has been deallocated")
                    return
                }
                let expectation = expectation(description: "Not expecting any events to occur for changeType (\(changeType)")
                expectation.isInverted = true
                let task = await expectationTaskStarted {
                    for await _ in recentItemsUseCase.eventsStream {
                        expectation.fulfill()
                        break
                    }
                }
                sut.updateWidgetContent(with: MockNodeList(nodes: mockNodes))
                await fulfillment(of: [expectation], timeout: 1)
                task.cancel()
            }
            
            if expectedResult {
                await expectingResultScenario(changeType, recentItemsUseCase)
            } else {
                await notExpectingResultScenario(changeType, recentItemsUseCase)
            }
        }
    }
}

extension QuickAccessWidgetManagerTests {
    
    func sut(recentItemsUseCase: MockRecentItemsUseCase = MockRecentItemsUseCase(),
             recentNodesUseCase: MockRecentNodesUseCase = MockRecentNodesUseCase(),
             favouriteItemsUseCase: MockFavouriteItemsUseCase = MockFavouriteItemsUseCase(),
             favouriteNodesUseCase: MockFavouriteNodesUseCase = MockFavouriteNodesUseCase(getAllFavouriteNodesWithSearchResult: .success([])),
             widgetCentre: MockWidgetCentre = MockWidgetCentre()) -> QuickAccessWidgetManager {
        QuickAccessWidgetManager(
            recentItemsUseCase: recentItemsUseCase,
            recentNodesUseCase: recentNodesUseCase,
            favouriteItemsUseCase: favouriteItemsUseCase,
            favouriteNodesUseCase: favouriteNodesUseCase,
            widgetCentre: widgetCentre)
    }
}
 
struct MockWidgetCentre: WidgetCentreProtocol {
 
    init() { }
    
    func reloadTimelines(ofKind kind: String) { }
    
    func reloadAllTimelines() { }
}
