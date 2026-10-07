import Foundation
@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewerPagingScrollObservationMonitorTests {
    private func makeSUT(
        dataSource: some PDFViewerPagingScrollObservationMonitorDataSource
    ) -> PDFViewerPagingScrollObservationMonitor {
        let sut = PDFViewerPagingScrollObservationMonitor()
        sut.dataSource = dataSource
        return sut
    }

    private func startListeningToKeyValueEvents(
        _ sut: PDFViewerPagingScrollObservationMonitor,
        keyPathObject: ObservablePagingState
    ) {
        sut.startListeningToPageUpdateEvents(
            notificationEventSource: .init(
                notificationNames: [],
                notificationObject: nil
            ),
            keyValueEventSource: .init(
                keyPath: \.value,
                keyPathObject: keyPathObject
            )
        )
    }

    @Test
    func refreshPrefersPageAtViewportCenter() {
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 2,
            estimatedCurrentPageIndex: 1
        )
        let sut = makeSUT(dataSource: dataSource)
        let observedObject = ObservablePagingState()
        var receivedPageIndex: Int?
        sut.onCurrentPageChange = { receivedPageIndex = $0 }

        startListeningToKeyValueEvents(sut, keyPathObject: observedObject)

        #expect(receivedPageIndex == 2)
    }

    @Test
    func refreshAtTopReportsPageAtViewportCenterAndScrolledToTop() {
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 2,
            estimatedCurrentPageIndex: 1,
            isScrolledToTop: true
        )
        let sut = makeSUT(dataSource: dataSource)
        let observedObject = ObservablePagingState()
        var receivedPageIndex: Int?
        var receivedIsScrolledToTop: Bool?
        sut.onCurrentPageChange = { receivedPageIndex = $0 }
        sut.onIsScrolledToTopChange = { receivedIsScrolledToTop = $0 }

        startListeningToKeyValueEvents(sut, keyPathObject: observedObject)

        #expect(receivedPageIndex == 2)
        #expect(receivedIsScrolledToTop == true)
    }

    @Test(.timeLimit(.minutes(1)))
    func scrolledToTopChangeIsReportedWhilePageStaysTheSame() async {
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 2,
            estimatedCurrentPageIndex: nil,
            isScrolledToTop: true
        )
        let sut = makeSUT(dataSource: dataSource)
        let observedObject = ObservablePagingState()
        var receivedPageIndices: [Int] = []
        var receivedIsScrolledToTop: [Bool] = []
        sut.onCurrentPageChange = { receivedPageIndices.append($0) }
        sut.onIsScrolledToTopChange = { receivedIsScrolledToTop.append($0) }
        startListeningToKeyValueEvents(sut, keyPathObject: observedObject)

        await withCheckedContinuation { continuation in
            sut.onIsScrolledToTopChange = { isScrolledToTop in
                receivedIsScrolledToTop.append(isScrolledToTop)
                continuation.resume()
            }
            dataSource.isScrolledToTop = false
            observedObject.value = 1
        }

        #expect(receivedPageIndices == [2])
        #expect(receivedIsScrolledToTop == [true, false])
    }

    @Test(.timeLimit(.minutes(1)))
    func unchangedScrolledToTopIsNotReportedAgain() async {
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 2,
            estimatedCurrentPageIndex: nil,
            isScrolledToTop: true
        )
        let sut = makeSUT(dataSource: dataSource)
        let observedObject = ObservablePagingState()
        var receivedPageIndices: [Int] = []
        var receivedIsScrolledToTop: [Bool] = []
        sut.onCurrentPageChange = { receivedPageIndices.append($0) }
        sut.onIsScrolledToTopChange = { receivedIsScrolledToTop.append($0) }
        startListeningToKeyValueEvents(sut, keyPathObject: observedObject)

        // The page change proves the re-check ran, and the top state is read
        // before the page in the same check.
        await withCheckedContinuation { continuation in
            sut.onCurrentPageChange = { pageIndex in
                receivedPageIndices.append(pageIndex)
                continuation.resume()
            }
            dataSource.currentPageIndexAtViewportCenter = 3
            observedObject.value = 1
        }

        #expect(receivedPageIndices == [2, 3])
        #expect(receivedIsScrolledToTop == [true])
    }

    @Test
    func refreshFallsBackToEstimatedPageAndSuppressesDuplicates() async {
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: nil,
            estimatedCurrentPageIndex: 1
        )
        let sut = makeSUT(dataSource: dataSource)
        let observedObject = ObservablePagingState()
        var receivedPageIndices: [Int] = []
        sut.onCurrentPageChange = { receivedPageIndices.append($0) }

        startListeningToKeyValueEvents(sut, keyPathObject: observedObject)
        observedObject.value = 1
        try? await Task.sleep(for: .milliseconds(600))

        #expect(receivedPageIndices == [1])
    }

    @Test
    func notificationBindingReportsPageChange() async {
        let notificationCenter = NotificationCenter()
        let firstNotificationName = Notification.Name("PDFViewerPagingScrollObservationMonitorTests.first")
        let secondNotificationName = Notification.Name("PDFViewerPagingScrollObservationMonitorTests.second")
        let observedObject = NSObject()
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 3,
            estimatedCurrentPageIndex: nil
        )
        let sut = makeSUT(dataSource: dataSource)

        let receivedPageIndex = await withCheckedContinuation { continuation in
            sut.onCurrentPageChange = { pageIndex in
                continuation.resume(returning: pageIndex)
            }
            sut.startListeningToPageUpdateEvents(
                notificationEventSource: .init(
                    notificationCenter: notificationCenter,
                    notificationNames: [firstNotificationName, secondNotificationName],
                    notificationObject: observedObject
                ),
                keyValueEventSource: nil as
                    PDFViewerPagingScrollObservationMonitor.KeyValueEventSource<
                        ObservablePagingState, Int
                    >?
            )
            Task { @MainActor in
                await Task.yield()
                notificationCenter.post(name: secondNotificationName, object: observedObject)
            }
        }

        #expect(receivedPageIndex == 3)
    }

    @Test
    func keyPathBindingReportsPageChange() async {
        let observedObject = ObservablePagingState()
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 4,
            estimatedCurrentPageIndex: nil
        )
        let sut = makeSUT(dataSource: dataSource)

        let receivedPageIndex = await withCheckedContinuation { continuation in
            sut.onCurrentPageChange = { pageIndex in
                continuation.resume(returning: pageIndex)
            }
            sut.startListeningToPageUpdateEvents(
                notificationEventSource: .init(
                    notificationNames: [],
                    notificationObject: nil
                ),
                keyValueEventSource: .init(
                    keyPath: \.value,
                    keyPathObject: observedObject
                )
            )

            observedObject.value = 1
        }

        #expect(receivedPageIndex == 4)
    }

    @Test
    func rebindingInvalidatesPreviousKeyPathObservation() async {
        let firstObservedObject = ObservablePagingState()
        let secondObservedObject = ObservablePagingState()
        let dataSource = MockPDFViewerPagingScrollObservationMonitorDataSource(
            currentPageIndexAtViewportCenter: 1,
            estimatedCurrentPageIndex: nil
        )
        let sut = makeSUT(dataSource: dataSource)
        var receivedPageIndices: [Int] = []
        sut.onCurrentPageChange = { receivedPageIndices.append($0) }
        sut.startListeningToPageUpdateEvents(
            notificationEventSource: .init(
                notificationNames: [],
                notificationObject: nil
            ),
            keyValueEventSource: .init(
                keyPath: \.value,
                keyPathObject: firstObservedObject
            )
        )

        firstObservedObject.value = 1
        await Task.yield()
        #expect(receivedPageIndices == [1])

        sut.startListeningToPageUpdateEvents(
            notificationEventSource: .init(
                notificationNames: [],
                notificationObject: nil
            ),
            keyValueEventSource: .init(
                keyPath: \.value,
                keyPathObject: secondObservedObject
            )
        )

        dataSource.currentPageIndexAtViewportCenter = 2
        firstObservedObject.value = 2
        secondObservedObject.value = 1
        try? await Task.sleep(for: .milliseconds(600))

        #expect(receivedPageIndices == [1, 1, 2])
    }
}

@MainActor
private final class MockPDFViewerPagingScrollObservationMonitorDataSource:
    PDFViewerPagingScrollObservationMonitorDataSource {
    var currentPageIndexAtViewportCenter: Int?
    var estimatedCurrentPageIndex: Int?
    var isScrolledToTop: Bool

    init(
        currentPageIndexAtViewportCenter: Int?,
        estimatedCurrentPageIndex: Int?,
        isScrolledToTop: Bool = false
    ) {
        self.currentPageIndexAtViewportCenter = currentPageIndexAtViewportCenter
        self.estimatedCurrentPageIndex = estimatedCurrentPageIndex
        self.isScrolledToTop = isScrolledToTop
    }
}

private final class ObservablePagingState: NSObject {
    @objc dynamic var value = 0
}
