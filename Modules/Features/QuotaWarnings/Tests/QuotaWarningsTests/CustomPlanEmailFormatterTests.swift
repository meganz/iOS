import MEGAL10n
@testable import QuotaWarnings
import Testing

@Suite("CustomPlanEmailFormatter")
struct CustomPlanEmailFormatterTests {
    private func makeSUT(appVersion: String = "18.12 (241100000)") -> CustomPlanEmailFormatter {
        CustomPlanEmailFormatter(appVersion: appVersion)
    }

    @Test func makeEmail_addressesTheSupportInbox() {
        let email = makeSUT().makeEmail(planName: "Pro III", userEmail: "user@mega.co.nz")

        #expect(email.recipients == ["support@mega.io"])
        #expect(email.subject == Strings.Localizable.upgradeToACustomPlan)
    }

    @Test func makeEmail_bodyCarriesTheVersionAndAccount() {
        let email = makeSUT(appVersion: "18.12 (1)").makeEmail(planName: "Pro III", userEmail: "user@mega.co.nz")

        #expect(email.body.hasPrefix(Strings.Localizable.askUsHowYouCanUpgradeToACustomPlan))
        #expect(email.body.contains("\(Strings.Localizable.appVersion) 18.12 (1)"))
        #expect(email.body.contains("user@mega.co.nz (Pro III)"))
    }

    @Test(arguments: [nil, ""])
    func makeEmail_withoutAnEmail_stillNamesThePlan(userEmail: String?) {
        let email = makeSUT().makeEmail(planName: "Pro Flexi", userEmail: userEmail)

        #expect(email.body.contains("(Pro Flexi)"))
        #expect(!email.body.contains(" (Pro Flexi)"))
    }

    /// The footer button opens this URL, so an unencodable body would leave the button dead.
    @Test func makeEmail_isAddressableAsAMailToURL() {
        let email = makeSUT().makeEmail(planName: "Pro III", userEmail: "user@mega.co.nz")

        #expect(email.mailToURL?.scheme == "mailto")
    }
}
