import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAPermissions
import MEGAPresentation
import SwiftUI

final class PermissionOnboardingViewModel: ViewModel<PermissionOnboardingViewModel.Route> {

    enum Route: Equatable {
        // When user choose to skip the screen
        case skipped
        // When user choose to request for permission and get a result - result is true if permission is granted.
        case finished(result: Bool)
    }

    let image: Image
    let title: String
    let description: String
    let note: String?

    let primaryButtonTitle: String
    let secondaryButtonTitle: String

    private let permissionHandler: any OnboardingPermissionHandling
    private let tracker: any AnalyticsTracking

    init(
        image: Image,
        title: String,
        description: String,
        note: String?,
        primaryButtonTitle: String,
        secondaryButtonTitle: String,
        permissionHandler: some OnboardingPermissionHandling,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.image = image
        self.title = title
        self.description = description
        self.note = note
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.permissionHandler = permissionHandler
        self.tracker = tracker
    }

    func onAppear() async {
        tracker.trackAnalyticsEvent(with: permissionHandler.screenViewEvent())
    }

    func onPrimaryButtonTap() async {
        tracker.trackAnalyticsEvent(with: permissionHandler.enablePermissionAnalyticsEvent())
        routeTo(.finished(result: await permissionHandler.requestPermission()))
        if let event = await permissionHandler.permissionResultAnalyticsEvent() {
            tracker.trackAnalyticsEvent(with: event)
        }
    }

    func onSecondaryButtonTap() async {
        tracker.trackAnalyticsEvent(with: permissionHandler.skipPermissionAnalyticsEvent())
        routeTo(.skipped)
    }
}
