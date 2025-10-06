@testable import MEGA
import MEGADomain
import XCTest

extension NodeSource {
    static var testBucket = NodeSource.mockRecentActionBucketEmpty
    static var testNode = NodeSource.node {
        NodeEntity(handle: 123)
    }
}

@MainActor
final class ViewModeFactoryTests: XCTestCase {
    
    class MockViewModeStore: ViewModeStoring {
        
        func viewMode(for location: ViewModeLocation) -> ViewModePreferenceEntity {
            viewModeToReturn
        }
        
        func save(viewMode: ViewModePreferenceEntity, for location: ViewModeLocation) {
            viewModesPassedIn.append(.init(viewMode: viewMode, location: location))
        }
        
        var viewModeToReturn: ViewModePreferenceEntity = .list
        var viewModesPassedIn = [ViewModePassedValues]()
        
        init() {}
        
        struct ViewModePassedValues {
            var viewMode: ViewModePreferenceEntity
            var location: ViewModeLocation
        }
    }

    @MainActor
    class Harness {
        let sut: ViewModeFactory
        let nodeSource: NodeSource
        var onlyMediaValueToReturn = false
        var config: NodeBrowserConfig = .default
        let store = MockViewModeStore()
        
        init(nodeSource: NodeSource) {
            self.nodeSource = nodeSource
            sut = ViewModeFactory(
                viewModeStore: store
            )
        }
        
        func determineResult() -> ViewModePreferenceEntity {
            sut.determineViewMode(
                nodeSource: nodeSource,
                config: config,
                hasOnlyMediaNodesChecker: { onlyMediaValueToReturn }
            )
        }
    }
    
    func testDetermineInitialViewMode_NodeSourceBucket_DefaultsToList() {
        let harness = Harness(nodeSource: .testBucket)
        let result = harness.determineResult()
        XCTAssertEqual(result, .list)
    }
    
    func testDetermineInitialViewMode_NodeSourceNode_ConfigAutoMDEnabled_FolderOnlyMedia_returnMediaDiscovery() {
        let harness = Harness(nodeSource: .testNode)
        harness.config.mediaDiscoveryAutomaticDetectionEnabled = { true }
        harness.onlyMediaValueToReturn = true
        let result = harness.determineResult()
        XCTAssertEqual(result, .mediaDiscovery)
    }
    
    func testDetermineInitialViewMode_NodeSourceNode_savedModeList_returnsList() {
        let harness = Harness(nodeSource: .testNode)
        harness.store.viewModeToReturn = .list
        let result = harness.determineResult()
        XCTAssertEqual(result, .list)
    }
    
    func testDetermineInitialViewMode_NodeSourceNode_savedModeThumbnail_returnsThumbnail() {
        let harness = Harness(nodeSource: .testNode)
        harness.store.viewModeToReturn = .thumbnail
        let result = harness.determineResult()
        XCTAssertEqual(result, .thumbnail)
    }
    
    // view mode store should not return anything other but .list of .thumbnail
    // but we test this as enum contains those values
    func testDetermineInitialViewMode_NodeSourceNode_savedModePerFolder_returnsLists() {
        let harness = Harness(nodeSource: .testNode)
        harness.store.viewModeToReturn = .perFolder
        let result = harness.determineResult()
        XCTAssertEqual(result, .list)
    }
    
    func testDetermineInitialViewMode_NodeSourceNode_savedModeMedia_returnsLists() {
        let harness = Harness(nodeSource: .testNode)
        harness.store.viewModeToReturn = .mediaDiscovery
        let result = harness.determineResult()
        XCTAssertEqual(result, .list)
    }
}
