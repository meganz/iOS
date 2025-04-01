@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGAL10n
import XCTest

final class SlideShowOptionViewModelTests: XCTestCase {
    private func cellViewModels() -> [SlideShowOptionCellViewModel] {
        [
            SlideShowOptionCellViewModel(
                name: .speed,
                title: Strings.Localizable.Slideshow.PreferenceSetting.speed,
                type: .detail, children: [
                    SlideShowOptionDetailCellViewModel(name: .speedNormal, title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.slow, isSelected: false)
                ], tracker: MockTracker())
        ]
    }
    
    private func getConfiguration() -> SlideShowConfigurationEntity {
        SlideShowConfigurationEntity(playingOrder: .shuffled, timeIntervalForSlideInSeconds: .normal, isRepeat: false, includeSubfolders: false)
    }
    
    func testDidSelectCell_forDetailCell_selected() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels(), currentConfiguration: getConfiguration())
        let cell = viewModel.cellViewModels.first
        viewModel.didSelectCell(cell!)
        XCTAssertTrue(viewModel.selectedCell === cell)
    }
    
    func testDidSelectCell_forNonDetailCell_notSelected() {
        let viewModel = SlideShowOptionViewModel(
            cellViewModels: [
                SlideShowOptionCellViewModel(name: .speed, title: "", type: .none, children: [], tracker: MockTracker())
            ],
            currentConfiguration: getConfiguration())
        let cell = viewModel.cellViewModels.first
        viewModel.didSelectCell(cell!)
        XCTAssertNil(viewModel.selectedCell)
    }
    
    func testNoCellTapped() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels(), currentConfiguration: getConfiguration())
        XCTAssertNil(viewModel.selectedCell)
    }
    
    func testGetNewConfiguration_whenRepeat_shouldReturnTrueForRepeat() throws {
        let cellViewModels = [
            SlideShowOptionCellViewModel(name: .repeat, title: "Repeat", type: .toggle, children: [], isOn: true, tracker: MockTracker())
        ]
        
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels, currentConfiguration: getConfiguration())
        let sut = viewModel.configuration()
        
        XCTAssertTrue(sut.isRepeat)
    }
    
    func testGetNewConfiguration_whenSpeedChangeToFast_shouldReturnFast() throws {
        let cellViewModels = [
            SlideShowOptionCellViewModel(name: .speed, title: "Speed", type: .detail, children: [
                SlideShowOptionDetailCellViewModel(name: .speedSlow, title: "Slow", isSelected: false),
                SlideShowOptionDetailCellViewModel(name: .speedNormal, title: "Normal", isSelected: false),
                SlideShowOptionDetailCellViewModel(name: .speedFast, title: "Fast", isSelected: true)
            ], tracker: MockTracker())
        ]
        
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels, currentConfiguration: getConfiguration())
        let sut = viewModel.configuration()
        
        XCTAssert(sut.timeIntervalForSlideInSeconds == SlideShowTimeIntervalOptionEntity.fast)
    }
    
    func testDidSelectCell_whenTypeOfCellIsDetail_shouldSendCorrectAnalyticEvent() {
        
        let expectations: [(SlideShowOptionName, any EventIdentifier)] = [
            (.speedNormal, SlideshowSettingSpeedNormalButtonEvent()),
            (.speedFast, SlideshowSettingSpeedFastButtonEvent()),
            (.speedSlow, SlideshowSettingSpeedSlowButtonEvent()),
            (.speedFast, SlideshowSettingSpeedFastButtonEvent()),
            (.orderShuffle, SlideshowSettingOrderShuffleButtonEvent()),
            (.orderNewest, SlideshowSettingOrderNewestButtonEvent()),
            (.orderOldest, SlideshowSettingOrderOldestButtonEvent())
        ]
        
        for (index, (name, event)) in expectations.enumerated() {
            let tracker = MockTracker()
            let sut = makeSUT(name: name, tracker: tracker)
            sut.didSelectChild(SlideShowOptionDetailCellViewModel(name: name, title: "", isSelected: false))
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [event],
                message: "Failed to get \(event.eventName) for index: \(index)")
        }
    }
    
    func testIsOnToggled_whenTypeOfCellIsToggleAndOptionIsRepeat_shouldSendCorrectAnalyticEvent() {
        let expectations: [(Bool, any EventIdentifier)] = [
            (true, SlideshowSettingRepeatOffButtonEvent()),
            (false, SlideshowSettingRepeatOnButtonEvent())
        ]
        
        for (index, (startingToggleValue, event)) in expectations.enumerated() {
            let tracker = MockTracker()
            let sut = makeSUT(name: .repeat, isOn: startingToggleValue, tracker: tracker)
            
            sut.isOn.toggle()
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [event],
                message: "Failed to get \(event.eventName) for index: \(index)")
        }
    }
    
    func testIsOnToggled_whenTypeOfCellIsToggleAndOptionIsNotRepeat_shouldNotSendAnalyticEvents() {
        let expectations: [SlideShowOptionName] = [
            .none,
            .order,
            .speed,
            .speedNormal,
            .speedSlow,
            .speedFast,
            .orderShuffle,
            .orderNewest,
            .orderOldest
        ]
        
        for (index, expectedName) in expectations.enumerated() {
            let tracker = MockTracker()
            let sut = makeSUT(name: expectedName, isOn: true, tracker: tracker)
            
            sut.isOn.toggle()
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [],
                message: "Failed to empty events for index: \(index)")
        }
    }
}

extension SlideShowOptionViewModelTests {
    private func makeSUT(id: String = "", name: SlideShowOptionName, title: String = "", type: SlideShowOptionCellViewModel.OptionType = .detail, children: [SlideShowOptionDetailCellViewModel] = [], isOn: Bool = false, tracker: some AnalyticsTracking = MockTracker(), file: StaticString = #file, line: UInt = #line) -> SlideShowOptionCellViewModel {

        let sut = SlideShowOptionCellViewModel(
            id: id,
            name: name,
            title: title,
            type: type,
            children: children,
            isOn: isOn,
            tracker: tracker)
        
        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }
}
