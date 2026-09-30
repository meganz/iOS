import Combine
import Foundation

@MainActor
protocol PDFViewerPagingScrollObservationMonitorDataSource: AnyObject {
    var currentPageIndexAtViewportCenter: Int? { get }
    var estimatedCurrentPageIndex: Int? { get }
}

@MainActor
final class PDFViewerPagingScrollObservationMonitor {
    struct NotificationEventSource {
        let notificationCenter: NotificationCenter
        let notificationNames: [Notification.Name]
        let notificationObject: AnyObject?

        init(
            notificationCenter: NotificationCenter = .default,
            notificationNames: [Notification.Name],
            notificationObject: AnyObject?
        ) {
            self.notificationCenter = notificationCenter
            self.notificationNames = notificationNames
            self.notificationObject = notificationObject
        }
    }

    struct KeyValueEventSource<ObservedObject: NSObject, Value> {
        let keyPath: KeyPath<ObservedObject, Value>
        let keyPathObject: ObservedObject
    }

    private var subscriptions = Set<AnyCancellable>()

    weak var dataSource: (any PDFViewerPagingScrollObservationMonitorDataSource)?
    private var lastReportedPageIndex: Int?
    var onCurrentPageChange: ((Int) -> Void)?

    /// Starts observing page updates from notifications and key-value changes.
    ///
    /// - Re-evaluates the page on throttled events and reports index changes.
    func startListeningToPageUpdateEvents<ObservedObject: NSObject, Value>(
        notificationEventSource: NotificationEventSource,
        keyValueEventSource: KeyValueEventSource<ObservedObject, Value>?
    ) {
        teardownExistingObservations()
        publisherFromEventSources(
            notificationEventSource: notificationEventSource,
            keyValueEventSource: keyValueEventSource
        ).throttle(
            for: .milliseconds(500),
            scheduler: DispatchQueue.main,
            latest: true
        )
        .sink { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkDataSourceCurrentPageAndReportIfNeeded()
            }
        }
        .store(in: &subscriptions)
        checkDataSourceCurrentPageAndReportIfNeeded()
    }

    // MARK: Private

    private func publisherFromEventSources<ObservedObject: NSObject, Value>(
        notificationEventSource: NotificationEventSource,
        keyValueEventSource: KeyValueEventSource<ObservedObject, Value>?
    ) -> some Publisher<Void, Never> {
        let notificationEvents = notificationEventSource.publisher
        let keyValueEvents = keyValueEventSource?.publisher
        return if let keyValueEvents {
            notificationEvents.merge(with: keyValueEvents).eraseToAnyPublisher()
        } else {
            notificationEvents.eraseToAnyPublisher()
        }
    }

    private func teardownExistingObservations() {
        subscriptions.removeAll()
        lastReportedPageIndex = nil
    }

    private func checkDataSourceCurrentPageAndReportIfNeeded() {
        guard let dataSource else { return }
        let pageIndex = dataSource.currentPageIndexAtViewportCenter
            ?? dataSource.estimatedCurrentPageIndex
        guard let pageIndex, lastReportedPageIndex != pageIndex else { return }
        lastReportedPageIndex = pageIndex
        onCurrentPageChange?(pageIndex)
    }
}

fileprivate extension PDFViewerPagingScrollObservationMonitor.NotificationEventSource {
    var publisher: some Publisher<Void, Never> {
        // NotificationCenter is shared, so scope events to the supplied object.
        let notificationObjectIdentifier = notificationObject.map(
            ObjectIdentifier.init
        )
        let publishersForNotificationNames = notificationNames.map { name in
            notificationCenter.publisher(for: name)
                .filter {
                    Self.notification($0, matchesObjectIdentifier: notificationObjectIdentifier)
                }
                .map { _ in }
        }
        return Publishers.MergeMany(publishersForNotificationNames)
    }

    private static func notification(
        _ notification: Notification,
        matchesObjectIdentifier notificationObjectIdentifier: ObjectIdentifier?
    ) -> Bool {
        guard let notificationObjectIdentifier else { return true }
        guard let object = notification.object else { return false }
        let objectIdentifier = ObjectIdentifier(object as AnyObject)
        return objectIdentifier == notificationObjectIdentifier
    }
}

fileprivate extension PDFViewerPagingScrollObservationMonitor.KeyValueEventSource {
    var publisher: some Publisher<Void, Never> {
        keyPathObject
            .publisher(for: keyPath, options: [.new])
            .map { _ in }
    }
}
