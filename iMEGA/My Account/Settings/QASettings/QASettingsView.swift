import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct QASettingsView: View {
    
    enum Constants {
        static let appUpdatesHeaderText = "App updates"
        static let featureListHeaderText = "Feature list"
        static let checkForUpdateText = "Check for updates"
        static let fingerprintVerificationHeaderText = "SDK secure flag"
        static let fingerprintVerificationFooterText = "To toggle secure flag: logout user > on onboarding screen > tap 5 times"
        static let fingerprintVerificationText = "Share secure flag: "
    }
    
    let viewModel: QASettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
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
                    Text(Constants.featureListHeaderText)
                    .textCase(nil)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)) {
                        FeatureFlagView()
                            .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
                    }
            
            Section(
                header:
                    Text(Constants.fingerprintVerificationHeaderText)
                    .textCase(nil)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI),
                
                footer:
                    Text(Constants.fingerprintVerificationFooterText)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)) {
                        Text(Constants.fingerprintVerificationText + viewModel.fingerprintVerificationFlagStatus())
                            .foregroundColor(TokenColors.Text.primary.swiftUI)
                            .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
                    }
        }
        .listStyle(.grouped)
        .padding(.top)
        .designTokenBackground(isDesignTokenEnabled)
    }
}
