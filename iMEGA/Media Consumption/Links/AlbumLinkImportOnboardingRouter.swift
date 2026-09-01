import UIKit

/// Takes a logged out tap on an album link action that needs an account -- `Save to MEGA`, `Copy to
/// Offline` -- to onboarding, the same way the file and folder link imports do through `ImportLinkRouter`.
///
/// Unlike those two, the album is not reopened once the user signs in: carrying an action across a login
/// means claiming a `LinkOption` and a matching branch in `MEGALinkManager.processSelectedOptionOnLink`,
/// which no album link has ever had. Stashing the link in `MEGALinkManager.linkURL` is not a shortcut to
/// it either -- `setAccountFirstLogin(_:)` clears that on the way in, and the first login path reads
/// `selectedOption` rather than the URL. Restoring the album after login is left to its own ticket.
@MainActor
protocol AlbumLinkImportOnboardingRouting {
    func showOnboarding()
}

struct AlbumLinkImportOnboardingRouter: AlbumLinkImportOnboardingRouting {
    func showOnboarding() {
        let navigationController = MEGANavigationController(rootViewController: OnboardingUSPViewController())
        navigationController.addRightCancelButton()
        UIApplication.mnz_visibleViewController().present(navigationController, animated: true)
    }
}
