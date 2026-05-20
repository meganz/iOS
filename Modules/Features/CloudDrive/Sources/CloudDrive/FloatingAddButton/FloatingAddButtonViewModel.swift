import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGASwift

@MainActor
public final class FloatingAddButtonViewModel: ObservableObject {
    private let floatingButtonVisibilityDataSource: any FloatingAddButtonVisibilityDataSourceProtocol
    public let uploadActions: [FloatingAddAction]

    @Published public private(set) var showsFloatingAddButton = false
    @Published public var showActions = false

    private var observingTask: Task<Void, Never>?

    var selectedAction: FloatingAddAction?

    let analyticsTracker: any AnalyticsTracking

    public init(
        floatingButtonVisibilityDataSource: some FloatingAddButtonVisibilityDataSourceProtocol,
        uploadActions: [FloatingAddAction],
        analyticsTracker: some AnalyticsTracking
    ) {
        self.floatingButtonVisibilityDataSource = floatingButtonVisibilityDataSource
        self.uploadActions = uploadActions
        self.analyticsTracker = analyticsTracker
        startObservingButtonVisibility()
    }

    public func addButtonTapAction() {
        toggleShowActions(true)
        analyticsTracker.trackAnalyticsEvent(with: CloudDriveFABPressedEvent())
    }

    public func toggleShowActions(_ shows: Bool) {
        showActions = shows
    }

    private func startObservingButtonVisibility() {
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
    public func saveSelectedAction(_ action: FloatingAddAction) {
        selectedAction = action
    }

    public func performSelectedActionAfterDismissal() {
        selectedAction?.action()
        selectedAction = nil
    }
}
