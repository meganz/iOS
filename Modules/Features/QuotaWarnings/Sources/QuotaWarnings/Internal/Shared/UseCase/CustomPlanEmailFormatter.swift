import MEGAInfrastructure
import MEGAL10n

/// Builds the pre-filled support email offered to users who are already on the highest plan, so support
/// receives the app version and the account a custom plan would be quoted for.
struct CustomPlanEmailFormatter {
    private let appVersion: String

    init(appVersion: String = AppInformation().completeAppVersion) {
        self.appVersion = appVersion
    }

    func makeEmail(planName: String, userEmail: String?) -> EmailEntity {
        EmailEntity(
            recipients: [Self.supportEmail],
            subject: Strings.Localizable.upgradeToACustomPlan,
            body: """
            \(Strings.Localizable.askUsHowYouCanUpgradeToACustomPlan)
            \(Self.writingSpace)
            \(Strings.Localizable.appVersion) \(appVersion)
            \(accountLine(planName: planName, userEmail: userEmail))
            """
        )
    }

    // MARK: - Private

    private func accountLine(planName: String, userEmail: String?) -> String {
        guard let userEmail, !userEmail.isEmpty else { return "(\(planName))" }
        return "\(userEmail) (\(planName))"
    }

    private static let supportEmail = "support@mega.io"

    /// Blank lines the user writes their request into, above the diagnostic footer.
    private static let writingSpace = Array(repeating: "\n", count: 6).joined()
}
