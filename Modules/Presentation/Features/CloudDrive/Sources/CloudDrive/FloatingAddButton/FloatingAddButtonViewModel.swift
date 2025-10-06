import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASwift

@MainActor
public final class FloatingAddButtonViewModel: ObservableObject {

    private let floatingButtonVisibilityDataSource: any FloatingAddButtonVisibilityDataSourceProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    @Published public private(set) var showsFloatingAddButton = false
    public let action: @MainActor () -> Void
    public init(
        floatingButtonVisibilityDataSource: some FloatingAddButtonVisibilityDataSourceProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        action: @escaping @MainActor () -> Void
    ) {
        self.action = action
        self.floatingButtonVisibilityDataSource = floatingButtonVisibilityDataSource
        self.featureFlagProvider = featureFlagProvider
        startObservingButtonVisibilityIfNeeded()
    }

    private func startObservingButtonVisibilityIfNeeded() {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) else {
            return
        }
        Task { [weak self, floatingButtonVisibilityDataSource] in
            for await isVisible in floatingButtonVisibilityDataSource.floatingButtonVisibility {
                self?.showsFloatingAddButton = isVisible
            }
        }
    }
}
