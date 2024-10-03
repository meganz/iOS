import MEGADomain
import MEGASwift

protocol CloudDriveViewModeMonitoring {
    func updatedViewModes(
        with nodeSource: NodeSource,
        currentViewMode: ViewModePreferenceEntity
    ) -> AnyAsyncSequence<ViewModePreferenceEntity>
}

final class CloudDriveViewModeMonitoringService: CloudDriveViewModeMonitoring {
    private let viewModeProvider: (NodeSource) async -> ViewModePreferenceEntity

    init(viewModeProvider: @escaping (NodeSource) async -> ViewModePreferenceEntity) {
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
