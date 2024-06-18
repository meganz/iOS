import MEGADomain

protocol CloudDriveViewModeMonitoring {
    var nodeSource: NodeSource { get set }
    var currentViewMode: ViewModePreferenceEntity { get set }

    var viewModes: AsyncStream<ViewModePreferenceEntity> { get }
}

final class CloudDriveViewModeMonitoringService: CloudDriveViewModeMonitoring {
    lazy var viewModes: AsyncStream<ViewModePreferenceEntity> = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
        }
    }()

    var nodeSource: NodeSource
    var currentViewMode: ViewModePreferenceEntity

    private let viewModeProvider: (NodeSource) async -> ViewModePreferenceEntity
    private var continuation: AsyncStream<ViewModePreferenceEntity>.Continuation?
    private var viewModePreferenceChangeNotificationTask: Task<Void, Never>?

    init(
        nodeSource: NodeSource,
        currentViewMode: ViewModePreferenceEntity,
        viewModeProvider: @escaping (NodeSource) async -> ViewModePreferenceEntity
    ) {
        self.nodeSource = nodeSource
        self.currentViewMode = currentViewMode
        self.viewModeProvider = viewModeProvider

        subscribeToViewModePreferenceChangeNotification()
    }

    deinit {
        cancelViewModePreferenceChangeNotification()
    }

    private func subscribeToViewModePreferenceChangeNotification() {
        viewModePreferenceChangeNotificationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .MEGAViewModePreferenceDidChange) {

                // One can enable or disable media discovery in the user interface settings.
                // This setting does not affect screens that are already displayed.
                // Media discovery view mode is not global; it only affects the current screen.
                // Therefore, there is no need to push notifications for media discovery view mode changes.
                if let self,
                   case let updatedViewMode = await viewModeProvider(nodeSource),
                   updatedViewMode != currentViewMode,
                   updatedViewMode != .mediaDiscovery {
                    continuation?.yield(updatedViewMode)
                }
            }
        }
    }

    private func cancelViewModePreferenceChangeNotification() {
        viewModePreferenceChangeNotificationTask?.cancel()
    }
}
