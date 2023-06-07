import XCTest
@testable import MEGA
import MEGADomain

final class ScheduleMeetingEndRecurrenceOptionsViewModelTests: XCTestCase {
    func testEndRecurrenceOptions_initialValue_shouldBeSixMonths() throws {
        let defaultEndDate = try XCTUnwrap(sixMonthsInAdvaceDate())
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(
            router: ScheduleMeetingEndRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity()
            )
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
                rules: ScheduledMeetingRulesEntity(until: endDate)
            )
        )
        viewModel.endRecurrenceNeverSelected()
        
        XCTAssert(viewModel.rules.until == nil)
    }
    
    func testEndRecurrenceOptions_dateSelected_shouldMatch() throws {
        let endDate = try XCTUnwrap(randomFutureDate())
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(
            router: ScheduleMeetingEndRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity()
            )
        )
        viewModel.endRecurrenceDate = endDate
        viewModel.endRecurrenceSelected()
        
        XCTAssert(viewModel.rules.until == endDate)
    }
    
    // MARK: - Private methods.
    private func randomFutureDate() -> Date? {
        Date(timeIntervalSinceNow: TimeInterval.random(in: 1...100000))
    }
    
    private func sixMonthsInAdvaceDate() -> Date? {
        Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: Date())
    }
}
