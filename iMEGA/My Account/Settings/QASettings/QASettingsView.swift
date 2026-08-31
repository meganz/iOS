#if DEBUG || QA_CONFIG

import MEGAAppPresentation
import MEGADesignToken
import MEGASwiftUI
import os
import SAMKeychain
import Settings
import SwiftUI

struct QASettingsView: View {
    
    enum Constants {
        static let appUpdatesHeaderText = "App updates"
        static let featureListHeaderText = "Feature list"
        static let checkForUpdateText = "Check for updates"
        static let userDataHeaderText = "User Data"
        static let clearStandardUserDefaultsText = "Clear Standard UserDefaults"
        static let quotaEventSimulatorText = "Quota dialog simulator"
        static let promoDialogText = "Promo dialog"
    }

    let viewModel: QASettingsViewModel

    var body: some View {
        List {
            Section(
                header:
                    Text(Constants.appUpdatesHeaderText)
                    .textCase(nil)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)) {
                        Button {
                            viewModel.checkForUpdate()
                        } label: {
                            Text(Constants.checkForUpdateText)
                        }
                    }
                    .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
            
            Section(
                header:
                    Text(Constants.userDataHeaderText)
                    .textCase(nil)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)) {
                        Button {
                            viewModel.clearStandardUserDefaults()
                        } label: {
                            Text(Constants.clearStandardUserDefaultsText)
                        }
                    }
                    .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)

            NavigationLink {
                KMTransferQASettingsView(
                    kmTransferUtils: DIContainer.kmTransferUtils,
                    onSimulateMigratedState: { Self.simulateMigratedKeychainState() }
                )
            } label: {
                Text("KM Transfer QA Settings")
            }
            
            NavigationLink {
                QuotaEventSimulatorView()
            } label: {
                Text(Constants.quotaEventSimulatorText)
            }

            NavigationLink {
                PromoDialogQASettingsView()
            } label: {
                Text(Constants.promoDialogText)
            }

            Section(
                header:
                    Text(Constants.featureListHeaderText)
                    .textCase(nil)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)) {
                        FeatureFlagView()
                            .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
                    }
        }
        .listStyle(.grouped)
        .background()
    }

    /// Deletes sessionV3 and the passcode items from the current keychain group while
    /// keeping statsid and the backup file, so the next launch exercises the import
    /// path exactly as after a keychain-group change. Passcode items are removed via
    /// SAMKeychain directly: the LTHPasscodeViewController path would rewrite the
    /// backup file from the now-session-less keychain and destroy the scenario.
    private static func simulateMigratedKeychainState() {
        let log = Logger(subsystem: "mega.ios.migration", category: "qa")
        let sessionDeleted = SAMKeychain.deletePassword(forService: "MEGA", account: "sessionV3")
        let passcodeAccounts = [
            "demoPasscode", "demoPasscodeTimerStart", "passcodeTimerDuration",
            "passcodeIsSimple", "passcodeType", "allowUnlockWithTouchID"
        ]
        var passcodeDeleted = 0
        for account in passcodeAccounts where SAMKeychain.deletePassword(forService: "demoServiceName", account: account) {
            passcodeDeleted += 1
        }
        let statsidStillPresent = SAMKeychain.password(forService: "MEGA", account: "statsid") != nil
        log.error("simulate: sessionDeleted=\(sessionDeleted, privacy: .public) passcodeDeleted=\(passcodeDeleted, privacy: .public)/6 statsidStillPresent=\(statsidStillPresent, privacy: .public) — kill and relaunch to run the import")
    }
}
#endif
