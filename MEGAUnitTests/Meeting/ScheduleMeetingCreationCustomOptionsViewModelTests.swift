import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock
import Combine

final class ScheduleMeetingCreationCustomOptionsViewModelTests: XCTestCase {
    var subscriptions = Set<AnyCancellable>()
    
    func testFrequency_whenSelectedFrequencyIsInvalid_shouldMatch() {
        assertFrequency(initialFrequency: .invalid, defaultsToFrequency: .daily)
    }
    
    func testFrequency_whenSelectedFrequencyIsDaily_shouldMatch() {
        assertFrequency(initialFrequency: .daily)
    }
    
    func testFrequency_whenSelectedFrequencyIsWeekly_shouldMatch() {
        assertFrequency(initialFrequency: .weekly)
    }
    
    func testFrequency_whenSelectedFrequencyIsMonthly_shouldMatch() {
        assertFrequency(initialFrequency: .monthly)
    }
    
    func testInterval_whenSelectedIntervalIsOne_shouldMatch() {
        assertInterval(1)
    }
    
    func testInterval_whenSelectedIntervalIsMoreThanOne_shouldMatch() {
        assertInterval(3)
    }
    
    func testIntervalFooterNote_forInvalidFrequency_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .invalid)
        XCTAssertEqual(
            viewModel.intervalFooterNote,
            ScheduleMeetingCreationIntervalFooterNote(rules: makeRules(withFrequency: .daily)).string
        )
    }
    
    func testIntervalFooterNote_forDailyFrequency_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        XCTAssertEqual(
            viewModel.intervalFooterNote,
            ScheduleMeetingCreationIntervalFooterNote(rules: makeRules(withFrequency: .daily)).string
        )
    }
    
    func testIntervalFooterNote_forWeeklyFrequency_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .weekly)
        XCTAssertEqual(
            viewModel.intervalFooterNote,
            ScheduleMeetingCreationIntervalFooterNote(rules: makeRules(withFrequency: .weekly)).string
        )
    }
    
    func testIntervalFooterNote_forMonthlyFrequency_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .monthly)
        XCTAssertEqual(
            viewModel.intervalFooterNote,
            ScheduleMeetingCreationIntervalFooterNote(rules: makeRules(withFrequency: .monthly)).string
        )
    }
    
    func testFrequencyNames_shouldMatch() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.frequencyNames, ScheduleMeetingCreationFrequencyOption.all.map(\.name))
    }
    
    func testSelectedFrequencyOption_forDaily_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        XCTAssertEqual(viewModel.selectedFrequencyOption, ScheduleMeetingCreationFrequencyOption.daily)
    }
    
    func testSelectedFrequencyOption_forWeekly_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .weekly)
        XCTAssertEqual(viewModel.selectedFrequencyOption, ScheduleMeetingCreationFrequencyOption.weekly)
    }
    
    func testSelectedFrequencyOption_forMonthly_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .monthly)
        XCTAssertEqual(viewModel.selectedFrequencyOption, ScheduleMeetingCreationFrequencyOption.monthly)
    }
    
    func testSelectedFrequencyOption_forCustomDaily_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.update(interval: 4)
        XCTAssertEqual(viewModel.selectedFrequencyOption, ScheduleMeetingCreationFrequencyOption.daily)
    }
    
    func testSelectedFrequencyOption_forCustomWeekly_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .weekly)
        viewModel.update(interval: 4)
        XCTAssertEqual(viewModel.selectedFrequencyOption, ScheduleMeetingCreationFrequencyOption.weekly)
    }
    
    func testSelectedFrequencyName_forDaily_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        XCTAssertEqual(viewModel.selectedFrequencyName, ScheduleMeetingCreationFrequencyOption.daily.name)
    }
    
    func testSelectedFrequencyName_forWeekly_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .weekly)
        XCTAssertEqual(viewModel.selectedFrequencyName, ScheduleMeetingCreationFrequencyOption.weekly.name)
    }
    
    func testSelectedFrequencyName_forMonthly_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .monthly)
        XCTAssertEqual(viewModel.selectedFrequencyName, ScheduleMeetingCreationFrequencyOption.monthly.name)
    }
    
    func testSelectedFrequencyName_forCustomDaily_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.update(interval: 4)
        XCTAssertEqual(viewModel.selectedFrequencyName, ScheduleMeetingCreationFrequencyOption.daily.name)
    }
    
    func testSelectedFrequencyName_forCustomWeekly_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .weekly)
        viewModel.update(interval: 4)
        XCTAssertEqual(viewModel.selectedFrequencyName, ScheduleMeetingCreationFrequencyOption.weekly.name)
    }
    
    func testRules_whenInitialStateIsInvalid_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .invalid)
        XCTAssertEqual(viewModel.rules.frequency, .daily)
        XCTAssertEqual(viewModel.rules.interval, 1)
        XCTAssertEqual(viewModel.rules.weekDayList, Array(1...7))
    }
    
    func testUpdateInterval_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.update(interval: 10)
        XCTAssertEqual(viewModel.interval, 10)
    }
    
    func testUpdateFrequency_shouldMatch() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.update(frequency: .monthly)
        XCTAssertEqual(viewModel.frequency, .monthly)
    }
    
    func testToggleFrequencyOption_whenCollapsed_shouldBeTrue() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.toggleFrequencyOption()
        XCTAssertTrue(viewModel.expandFrequency)
    }
    
    func testToggleIntervalOption_whenCollapsed_shouldBeTrue() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.toggleIntervalOption()
        XCTAssertTrue(viewModel.expandInterval)
    }
    
    func testToggleFrequencyOption_whenExpanded_shouldBeFalse() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.toggleFrequencyOption()
        viewModel.toggleFrequencyOption()
        XCTAssertFalse(viewModel.expandFrequency)
    }
    
    func testToggleIntervalOption_whenExpanded_shouldBeFalse() {
        let viewModel = makeViewModel(withFrequency: .daily)
        viewModel.toggleIntervalOption()
        viewModel.toggleIntervalOption()
        XCTAssertFalse(viewModel.expandInterval)
    }
    
    func testUpdateFrequency_fromDailyToWeekly_shouldMatch() throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let viewModel = makeViewModel(withFrequency: .daily, startDate: sampleDate)
        
        let expectation = XCTestExpectation(description: "Convert daily to weekly recurrrence")
        viewModel
            .$rules
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        viewModel.selectedFrequencyName = viewModel.frequencyNames[1]
        XCTAssertEqual(viewModel.rules.weekDayList, [3])
    }
    
    func testUpdateFrequency_fromDailyToMonthly_shouldMatch() throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let viewModel = makeViewModel(withFrequency: .daily, startDate: sampleDate)
        
        let expectation = XCTestExpectation(description: "Convert daily to monthly recurrrence")
        viewModel
            .$rules
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        viewModel.selectedFrequencyName = viewModel.frequencyNames[2]
        XCTAssertEqual(viewModel.rules.monthDayList, [14])
    }
    
    func testUpdateFrequency_fromWeeklyToMonthly_shouldMatch() throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let viewModel = makeViewModel(withFrequency: .weekly, startDate: sampleDate)
        
        let expectation = XCTestExpectation(description: "Convert weekly to monthly recurrrence")
        viewModel
            .$rules
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        viewModel.selectedFrequencyName = viewModel.frequencyNames[2]
        XCTAssertEqual(viewModel.rules.monthDayList, [14])
    }
    
    // MARK: - Private methods
    
    private func assertFrequency(
        initialFrequency: ScheduledMeetingRulesEntity.Frequency,
        defaultsToFrequency: ScheduledMeetingRulesEntity.Frequency? = nil
    ) {
        let viewModel = makeViewModel(withFrequency: initialFrequency, interval: 1)
        XCTAssertEqual(viewModel.frequency, defaultsToFrequency ?? initialFrequency)
    }
    
    private func assertInterval(_ interval: Int) {
        let viewModel = makeViewModel(withFrequency: .daily, interval: interval)
        XCTAssertEqual(viewModel.interval, interval)
    }
    
    private func makeViewModel(
        withFrequency frequency: ScheduledMeetingRulesEntity.Frequency = .invalid,
        interval: Int = 1,
        startDate: Date = Date()
    ) -> ScheduleMeetingCreationCustomOptionsViewModel {
        ScheduleMeetingCreationCustomOptionsViewModel(
            router: MockScheduleMeetingCreationCustomOptionsRouter(),
            rules: makeRules(withFrequency: frequency, interval: interval),
            startDate: startDate
        )
    }
    
    private func makeRules(
        withFrequency frequency: ScheduledMeetingRulesEntity.Frequency = .invalid,
        interval: Int = 1,
        startDate: Date = Date()
    ) -> ScheduledMeetingRulesEntity {
        var rules = ScheduledMeetingRulesEntity(frequency: frequency, interval: interval)
        rules.updateDayList(usingStartDate: startDate)
        return rules
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "14/06/2023")
    }
}

final class MockScheduleMeetingCreationCustomOptionsRouter: ScheduleMeetingCreationCustomOptionsRouting {
    func start() {}
}
