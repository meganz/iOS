@testable import MEGA
import XCTest

final class RegionListViewModelTests: XCTestCase {
    private let nzRegion = SMSRegion(regionCode: "NZ", displayCallingCode: "+64", displayName: "New Zealand (+64)")
    private let auRegion = SMSRegion(regionCode: "AU", displayCallingCode: "+61", displayName: "Australia (+61)")
    private let austriaRegion = SMSRegion(regionCode: "AT", displayCallingCode: "+43", displayName: "Austria (+43)")
    private let usRegion = SMSRegion(regionCode: "US", displayCallingCode: "+1", displayName: "United States (+1)")
    private let collation = UILocalizedIndexedCollation.current()
    
    private lazy var sortedRegions = collation.sortedArray(from: [nzRegion, auRegion, usRegion, austriaRegion],
                                                          collationStringSelector: #selector(getter: SMSRegion.displayName)) as? [SMSRegion] ?? []
    private lazy var indexedRegions: [[SMSRegion]] = {
        var sections = collation.sectionTitles.map { _ in [SMSRegion]() }
        for country in sortedRegions {
            let sectionIndex = collation.section(for: country, collationStringSelector: #selector(getter: SMSRegion.displayName))
            sections[sectionIndex].append(country)
        }
        
        return sections
    }()
    
    @MainActor func testAction_onViewReady() {
        let sut = RegionListViewModel(router: MockRegionListViewRouter(),
                                      regionCodes: sortedRegions,
                                      collation: collation)
        test(viewModel: sut,
             action: RegionListAction.onViewReady,
             expectedCommands: [.reloadIndexedRegions(indexedRegions, collation: collation)])
    }
    
    @MainActor func testAction_startSearching() {
        let sut = RegionListViewModel(router: MockRegionListViewRouter(),
                                      regionCodes: sortedRegions,
                                      collation: collation)
        test(viewModel: sut,
             action: RegionListAction.startSearching("austr"),
             expectedCommands: [.reloadSearchedRegions([auRegion, austriaRegion])])
    }
    
    @MainActor func testAction_finishSearching() {
        let sut = RegionListViewModel(router: MockRegionListViewRouter(),
                                      regionCodes: sortedRegions,
                                      collation: collation)
        test(viewModel: sut,
             action: RegionListAction.onViewReady,
             expectedCommands: [.reloadIndexedRegions(indexedRegions, collation: collation)])
        
        test(viewModel: sut,
             action: RegionListAction.startSearching("austr"),
             expectedCommands: [.reloadSearchedRegions([auRegion, austriaRegion])])
        
        test(viewModel: sut,
             action: RegionListAction.finishSearching,
             expectedCommands: [.reloadIndexedRegions(indexedRegions, collation: collation)])
    }
    
    @MainActor func testAction_didSelectRegion() {
        let router = MockRegionListViewRouter()
        let sut = RegionListViewModel(router: router,
                                      regionCodes: sortedRegions,
                                      collation: collation)
        test(viewModel: sut,
             action: RegionListAction.didSelectRegion(auRegion),
             expectedCommands: [])
        XCTAssertEqual(router.goToRegion_calledTimes, 1)
    }
}

final class MockRegionListViewRouter: RegionListViewRouting {
    var goToRegion_calledTimes = 0
    
    func goToRegion(_ region: SMSRegion) {
        goToRegion_calledTimes += 1
    }
}
