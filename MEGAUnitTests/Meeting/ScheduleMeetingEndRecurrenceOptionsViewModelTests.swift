@testable import MEGA
import MEGADomain
import XCTest

final class ScheduleMeetingEndRecurrenceOptionsViewModelTests: XCTestCase {
    func testEndRecurrenceOptions_initialValue_shouldBeSixMonths() throws {
        let startDate = try XCTUnwrap(randomFutureDate())
        let defaultEndDate = try XCTUnwrap(addSixMonthsToDate(startDate))
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(
            router: ScheduleMeetingEndRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity(),
                startDate: startDate
            ),
            startDate: startDate
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        XCTAssert(dateFormatter.string(from: viewModel.endRecurrenceDate) == dateFormatter.string(from: defaultEndDate))
    }
    
    func testEndRecurrenceOptions_neverSelected_shouldMatch() throws {
        let endDate = try XCTUnwrap(randomFutureDate())
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(
            router: ScheduleMeetingEndRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity(until: endDate),
                startDate: Date()
            ),
            startDate: Date()
        )
        viewModel.endRecurrenceNeverSelected()
        
        XCTAssert(viewModel.rules.until == nil)
    }
    
    func testEndRecurrenceOptions_dateSelected_shouldMatch() throws {
        let endDate = try XCTUnwrap(randomFutureDate())
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(
            router: ScheduleMeetingEndRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity(),
                startDate: Date()
            ),
            startDate: Date()
        )
        viewModel.endRecurrenceDate = endDate
        viewModel.endRecurrenceSelected()
        
        XCTAssert(viewModel.rules.until == endDate)
    }
    
    // MARK: - Private methods.
    private func randomFutureDate() -> Date? {
        Date(timeIntervalSinceNow: TimeInterval.random(in: 1...100000))
    }
    
    private func addSixMonthsToDate(_ date: Date) -> Date? {
        Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: date)
    }
}
