import MEGAInfrastructure
import MEGAPresentation
import SwiftUI

struct PermissionOnboardingViewModel {
    let image: ImageResource
    let title: String
    let description: String
    let note: String?

    let primaryButtonTitle: String
    let secondaryButtonTitle: String

    init() {
        image = .notificationCta
        title = "Never miss an important update"
        description =
        """
        Stay informed with real-time updates that matter to you. Get alerts for shared folder activity, security updates, and exclusive offers so you never miss anything important.

        You can manage notification preferences at any time in your device settings.
        """
        note = "Automatic camera uploads requires **Full Access** to your device photo library"
        primaryButtonTitle = "Enable Notifications"
        secondaryButtonTitle = "Skip for now"
    }

    func onPrimaryButtonTap() {
        // Inject biz logic later
    }

    func onSecondaryButtonTap() {
        // Inject biz logic later
    }
}
