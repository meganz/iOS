import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGASwift

@MainActor
public final class FloatingAddButtonViewModel: ObservableObject {
    private let floatingButtonVisibilityDataSource: any FloatingAddButtonVisibilityDataSourceProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    public let uploadActions: [NodeUploadAction]

    @Published public private(set) var showsFloatingAddButton = false
    @Published public var showActions = false

    private var observingTask: Task<Void, Never>?

    var selectedAction: NodeUploadAction?

    let analyticsTracker: any AnalyticsTracking

    public init(
        floatingButtonVisibilityDataSource: some FloatingAddButtonVisibilityDataSourceProtocol,
        uploadActions: [NodeUploadAction],
        featureFlagProvider: some FeatureFlagProviderProtocol,
        analyticsTracker: some AnalyticsTracking
    ) {
        self.floatingButtonVisibilityDataSource = floatingButtonVisibilityDataSource
        self.uploadActions = uploadActions
        self.featureFlagProvider = featureFlagProvider
        self.analyticsTracker = analyticsTracker
        startObservingButtonVisibilityIfNeeded()
    }

    public func addButtonTapAction() {
        toggleShowActions(true)
        analyticsTracker.trackAnalyticsEvent(with: CloudDriveFABPressedEvent())
    }

    public func toggleShowActions(_ shows: Bool) {
        showActions = shows
    }

    private func startObservingButtonVisibilityIfNeeded() {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) else {
            return
        }
        observingTask = Task { [weak self, floatingButtonVisibilityDataSource] in
            for await isVisible in floatingButtonVisibilityDataSource.floatingButtonVisibility {
                guard !Task.isCancelled else { break }
                self?.showsFloatingAddButton = isVisible
            }
        }
    }

    deinit {
        observingTask?.cancel()
        observingTask = nil
    }
}

extension FloatingAddButtonViewModel: NodeUploadActionSheetViewModelProtocol {
    public func saveSelectedAction(_ action: NodeUploadAction) {
        selectedAction = action
    }

    public func performSelectedActionAfterDismissal() {
        selectedAction?.action()
        selectedAction = nil
    }
}
