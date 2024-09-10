import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct QASettingsView: View {
    
    enum Constants {
        static let appUpdatesHeaderText = "App updates"
        static let featureListHeaderText = "Feature list"
        static let checkForUpdateText = "Check for updates"
        static let userDataHeaderText = "User Data"
        static let clearStandardUserDefaultsText = "Clear Standard UserDefaults"
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
        .padding(.top)
        .background()
    }
}
