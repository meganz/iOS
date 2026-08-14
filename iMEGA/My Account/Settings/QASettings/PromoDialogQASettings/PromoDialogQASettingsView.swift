import Accounts
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import SwiftUI

#if DEBUG || QA_CONFIG
/// QA-only screen for the promotional offer landing dialog's app-open trigger.
///
/// The reshow interval comes from the API (`utqa` `mo.r`) and can be days long, so the stored showings — one per
/// campaign the account has been shown — are editable here: reset them to get the dialog back on the next app
/// open, or backdate them to cross the interval without waiting it out.
@MainActor
struct PromoDialogQASettingsView: View {
    /// One line per campaign shown to this account, or a single line saying why there is nothing to show.
    @State private var storedRecords: [String] = []

    private let accountUseCase: any AccountUseCaseProtocol

    init(accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo)) {
        self.accountUseCase = accountUseCase
    }

    /// The stored showings for the account currently in. Read per access rather than built once, so the screen
    /// follows a login as another account: the showings are keyed on the account handle.
    private var qaStore: PromoDialogReshowQAStore? {
        accountUseCase.currentUserHandle.map(PromoDialogReshowQAStore.init(accountHandle:))
    }

    var body: some View {
        List {
            Section(header: header("Stored showings (this account, one per campaign)")) {
                ForEach(storedRecords, id: \.self) { record in
                    Text(record)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                }

                Button("Reset stored showings") {
                    qaStore?.reset()
                    refresh()
                }

                Button("Backdate by 1 hour") {
                    qaStore?.backdateShownDates(by: 3600)
                    refresh()
                }

                Button("Backdate by 1 day") {
                    qaStore?.backdateShownDates(by: 86400)
                    refresh()
                }
            }

            Section(header: header("Triggers")) {
                Button("Run the app-open trigger now") {
                    PromoLandingDialogLaunchPresenter.shared.triggerIfNeeded()
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Promo dialog")
        .onAppear(perform: refresh)
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .textCase(nil)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }

    private func refresh() {
        guard let qaStore else {
            storedRecords = ["Not logged in"]
            return
        }
        let records = qaStore.storedRecordDescriptions
        storedRecords = records.isEmpty ? ["Never shown"] : records
    }
}
#endif
