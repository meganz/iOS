import MEGAInfrastructure
import MEGAL10n
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
        title = Strings.Localizable.Onboarding.Cta.CameraBackups.title
        description = Strings.Localizable.Onboarding.Cta.CameraBackups.explanation
        note = Strings.Localizable.Onboarding.Cta.CameraBackups.note
        primaryButtonTitle = Strings.Localizable.Onboarding.Cta.CameraBackups.Buttons.enable
        secondaryButtonTitle = Strings.Localizable.Onboarding.Cta.CameraBackups.Buttons.skip
    }

    func onPrimaryButtonTap() {
        // Inject biz logic later
    }

    func onSecondaryButtonTap() {
        // Inject biz logic later
    }
}
