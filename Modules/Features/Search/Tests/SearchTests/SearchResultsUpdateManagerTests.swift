@testable import Search
import SearchMock
import XCTest

final class SearchResultsUpdateManagerTests: XCTestCase {

    func testProcessSignals_whenNoSignals_shouldMatchNoneCase() {
        let sut = makeSUT()
        match(result: sut.processSignals(), with: .none)
    }

    func testProcessSignals_whenOneGenericSignal_shouldMatchGenericCase() {
        let sut = makeSUT(signals: [.generic])
        match(result: sut.processSignals(), with: .generic)
    }

    func testProcessSignals_whenMultipleGenericSignals_shouldMatchGenericCase() {
        let sut = makeSUT(signals: [.generic, .generic])
        match(result: sut.processSignals(), with: .generic)
    }

    func testProcessSignals_whenMixOfGenericAndSpecificSignals_shouldReturnGenericResult() {
        let specificResults: [SearchResult] = [.resultWith(id: 100), .resultWith(id: 200)]
        let sut = makeSUT(
            signals: [
                .generic,
                .specific(result: specificResults[0]),
                .generic,
                .specific(result: specificResults[1])
            ]
        )
        match(result: sut.processSignals(), with: .generic)
    }

    func testProcessSignals_whenMultipleSpecificSignals_shouldReturnSpecificUpdateResults() {
        let specificResults: [SearchResult] = [.resultWith(id: 100), .resultWith(id: 200)]
        let sut = makeSUT(
            signals: [
                .specific(result: specificResults[0]),
                .specific(result: specificResults[1])
            ]
        )
        match(result: sut.processSignals(), with: .specificUpdateResults(specificResults))
    }

    // MARK: - Helpers

    private func makeSUT(
        signals: [SearchResultUpdateSignal] = []
    ) -> SearchResultsUpdateManager {
        SearchResultsUpdateManager(signals: signals)
    }

    private func match(
        result: SearchResultsUpdateManager.Result,
        with expected: SearchResultsUpdateManager.Result,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch (result, expected) {
        case (.none, .none), (.generic, .generic):
            break
        case (.specificUpdateResults(let results), .specificUpdateResults(let expectedResults)):
            XCTAssertEqual(results, expectedResults, "Search Results does not match", file: file, line: line)
        default:
            XCTFail("expected \(expected) but returned \(result)", file: file, line: line)
        }
    }
}
