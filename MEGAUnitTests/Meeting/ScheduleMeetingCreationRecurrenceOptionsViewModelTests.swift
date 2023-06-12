import XCTest
@testable import MEGA
import MEGADomain
import Combine

final class ScheduleMeetingCreationRecurrenceOptionsViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    func testRecurrenceOptions_forNonCustomizedOptions_shouldMatch() {
        XCTAssertEqual(try makeViewModel().nonCustomizedOptions(), [.never, .daily, .weekly, .monthly])
    }
    
    func testRecurrenceOptions_forCustomizedOption_shouldMatch() {
        XCTAssertEqual(try makeViewModel().customizedOption(), .custom)
    }
    
    func testCustomOptionFooterNote_withDailyOption_shouldBeNil() throws {
        let viewModel = try makeViewModel(frequency: .daily, weekDayList: Array(1...7))
        XCTAssertNil(viewModel.customOptionFooterNote())
    }
    
    func testCustomOptionFooterNote_withCustomOption_shouldNotBeNil() throws {
        let viewModel = try makeViewModel(frequency: .daily, weekDayList: [1, 2])
        XCTAssertNotNil(viewModel.customOptionFooterNote())
    }
    
    func testNavigateToCustomOptionsScreen_shouldMatch() {
        let router = MockScheduleMeetingCreationRecurrenceOptionsRouter()
        let viewModel = ScheduleMeetingCreationRecurrenceOptionsViewModel(router: router)
        viewModel.navigateToCustomOptionsScreen()
        XCTAssert(router.navigateToCustomOptionsScreen_CalledTimes == 1)
    }
    
    func testupdateSelection_toWeekly_shouldMatch() throws {
        let viewModel = try makeViewModel()
        viewModel.updateSelection(withRecurrenceOption: .daily)
        XCTAssertEqual(viewModel.rules.frequency, .daily)
        XCTAssertEqual(viewModel.rules.weekDayList, Array(1...7))
        XCTAssertEqual(viewModel.rules.interval, 1)
    }
    
    func testupdateSelection_toMonthly_shouldMatch() throws {
        let viewModel = try makeViewModel()
        viewModel.updateSelection(withRecurrenceOption: .monthly)
        XCTAssertEqual(viewModel.rules.frequency, .monthly)
        XCTAssertEqual(viewModel.rules.monthDayList, [16])
        XCTAssertEqual(viewModel.rules.interval, 1)
    }
    
    func testDismiss_shouldMatch() {
        let router = MockScheduleMeetingCreationRecurrenceOptionsRouter()
        let viewModel = ScheduleMeetingCreationRecurrenceOptionsViewModel(router: router)
        viewModel.dismiss()
        XCTAssert(router.dismiss_CalledTimes == 1)
    }
    
    // MARK: - Private methods.
    
    private func makeViewModel(
        rules: ScheduledMeetingRulesEntity = ScheduledMeetingRulesEntity(frequency: .invalid),
        startDate: Date? = nil
    ) throws -> ScheduleMeetingCreationRecurrenceOptionsViewModel {
        let sampleDate = try XCTUnwrap(sampleDate())
        return ScheduleMeetingCreationRecurrenceOptionsViewModel(
            router: MockScheduleMeetingCreationRecurrenceOptionsRouter(rules: rules, startDate: startDate ?? sampleDate)
        )
    }
    
    private func makeViewModel(
        frequency: ScheduledMeetingRulesEntity.Frequency = .invalid,
        weekDayList: [Int]
    ) throws -> ScheduleMeetingCreationRecurrenceOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(frequency: frequency, interval: 1, weekDayList: weekDayList)
        return try makeViewModel(rules: rules)
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "16/05/2023")
    }
}

final class MockScheduleMeetingCreationRecurrenceOptionsRouter: ScheduleMeetingCreationRecurrenceOptionsRouting {
    var rules: ScheduledMeetingRulesEntity
    var startDate: Date
    var navigateToCustomOptionsScreen_CalledTimes = 0
    var dismiss_CalledTimes = 0
    
    init(
        rules: ScheduledMeetingRulesEntity = ScheduledMeetingRulesEntity(frequency: .invalid),
        startDate: Date = Date()
    ) {
        self.rules = rules
        self.startDate = startDate
    }
    
    func start() -> ScheduleMeetingCreationRecurrenceOptionsViewModel {
        ScheduleMeetingCreationRecurrenceOptionsViewModel(router: self)
    }
    
    func navigateToCustomOptionsScreen() {
        navigateToCustomOptionsScreen_CalledTimes += 1
    }
    
    func dismiss() {
        dismiss_CalledTimes += 1
    }
}
