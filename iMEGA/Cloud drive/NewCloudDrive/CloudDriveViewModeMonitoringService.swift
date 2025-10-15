import MEGADomain
import MEGASwift

protocol CloudDriveViewModeMonitoring: Sendable {
    func updatedViewModes(
        with nodeSource: NodeSource,
        currentViewMode: ViewModePreferenceEntity
    ) -> AnyAsyncSequence<ViewModePreferenceEntity>
}

final class CloudDriveViewModeMonitoringService: CloudDriveViewModeMonitoring {
    private let viewModeProvider: @Sendable (NodeSource) async -> ViewModePreferenceEntity

    init(viewModeProvider: @escaping @Sendable (NodeSource) async -> ViewModePreferenceEntity) {
        self.viewModeProvider = viewModeProvider
    }

    func updatedViewModes(
        with nodeSource: NodeSource,
        currentViewMode: ViewModePreferenceEntity
    ) -> AnyAsyncSequence<ViewModePreferenceEntity> {
        NotificationCenter
            .default
            .notifications(named: .MEGAViewModePreferenceDidChange)
            .compactMap { _ async -> ViewModePreferenceEntity? in
                guard case let updatedViewMode = await self.viewModeProvider(nodeSource),
                      updatedViewMode != currentViewMode,
                      updatedViewMode != .mediaDiscovery else {
                    return nil
                }

                return updatedViewMode
            }
            .eraseToAnyAsyncSequence()
    }
}
