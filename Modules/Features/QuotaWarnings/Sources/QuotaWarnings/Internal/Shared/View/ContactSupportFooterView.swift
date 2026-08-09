import MEGAInfrastructure
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct ContactSupportFooterView: View {
    private let email: EmailEntity
    private let openLink: (URL, URL) -> Void

    init(
        email: EmailEntity,
        openLink: @escaping (URL, URL) -> Void = { url, fallbackURL in
            DependencyInjection.externalLinkOpener.openExternalLink(with: url, fallbackURL: fallbackURL)
        }
    ) {
        self.email = email
        self.openLink = openLink
    }

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.Accounts.CancelSubscriptionErrorAlert.Button.contactHelpdesk,
                    type: .textOnly,
                    action: contactSupport
                )
            ],
            allowMaxWidthForWideScreen: true
        )
    }

    private func contactSupport() {
        guard let mailToURL = email.mailToURL else { return }
        openLink(mailToURL, Self.helpCentreURL)
    }

    private static let helpCentreURL = URL(string: "https://help.mega.io")!
}

#Preview {
    ContactSupportFooterView(
        email: EmailEntity(
            recipients: ["support@mega.io"],
            subject: "Upgrade to a custom plan",
            body: "Ask us how you can upgrade to a custom plan:"
        ),
        openLink: { _, _ in }
    )
}
