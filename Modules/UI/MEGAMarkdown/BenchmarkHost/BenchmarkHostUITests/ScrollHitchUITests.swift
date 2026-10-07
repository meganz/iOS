import MEGABenchmarkUI
import XCTest

/// Apple's hitch numbers for fast flings through a big preview.
/// Every section of the file has its own text and size. A file of one repeated section hides the cost of new rows.
/// `XCTHitchMetric` gives values on a device only. A simulator returns the scroll duration alone.
/// Apple rates a hitch time ratio under 5 ms/s as good and over 10 ms/s as bad.
@available(iOS 26.0, *)
final class ScrollHitchUITests: XCTestCase {
    private static let flings = 3
    private static let loadingFlings = 6

    /// Every run reaches rows that never showed, so each new cell sizes itself and corrects its guessed height.
    func testFlingThroughNewRows() throws {
        let app = launch(megabytes: 2)
        let list = try previewList(in: app)
        measure(metrics: ScrollBenchmark.hitchMetrics(for: app), options: ScrollBenchmark.measureOptions()) {
            ScrollBenchmark.fling(list, up: Self.flings)
        }
    }

    /// The runs fling over rows that already showed, so cells keep their measured height.
    /// The rows reached can differ a little from the warm-up rows, because each fling ends at another place.
    func testFlingThroughMeasuredRows() throws {
        let app = launch(megabytes: 2)
        let list = try previewList(in: app)
        measure(metrics: ScrollBenchmark.hitchMetrics(for: app), options: ScrollBenchmark.measureOptions(manualStart: true)) {
            ScrollBenchmark.fling(list, up: Self.flings + 1)
            ScrollBenchmark.fling(list, down: Self.flings + 1)
            startMeasuring()
            ScrollBenchmark.fling(list, up: Self.flings)
            stopMeasuring()
            ScrollBenchmark.fling(list, down: Self.flings + 1)
        }
    }

    /// Flings while a 50 MB file still loads, so each parse batch adds its rows during the scroll.
    /// The file loads in about 7 s on an iPhone 15. Each run opens it again, because a loaded file adds no rows.
    func testFlingWhileLargeFileLoads() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-varied-mb", "50"]
        measure(metrics: ScrollBenchmark.hitchMetrics(for: app), options: ScrollBenchmark.measureOptions(manualStart: true)) {
            app.launch()
            let list = app.collectionViews.firstMatch
            XCTAssertTrue(ScrollBenchmark.waitForFirstCell(in: list), "The preview showed no rows.")
            startMeasuring()
            ScrollBenchmark.fling(list, up: Self.loadingFlings)
            stopMeasuring()
            app.terminate()
        }
    }

    // MARK: - Helpers

    private func launch(megabytes: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-varied-mb", String(megabytes)]
        app.launch()
        return app
    }

    private func previewList(in app: XCUIApplication) throws -> XCUIElement {
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(ScrollBenchmark.waitForFirstCell(in: list), "The preview showed no rows.")
        return list
    }
}
