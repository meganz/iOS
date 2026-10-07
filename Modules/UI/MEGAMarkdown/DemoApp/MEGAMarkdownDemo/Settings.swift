import SwiftUI

/// Keys of the values the demo keeps in `UserDefaults`.
enum SettingsKey {
    /// For example `https://github.com/owner/repo/blob/main`. Empty hides the GitHub button.
    static let gitHubBaseURL = "gitHubBaseURL"
}

enum SettingsDefault {
    /// The repo that holds a copy of the test files.
    static let gitHubBaseURL = "https://github.com/mega-bl/markdown-test-files/blob/main"
}

struct SettingsView: View {
    @AppStorage(SettingsKey.gitHubBaseURL) private var gitHubBaseURL = SettingsDefault.gitHubBaseURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://github.com/owner/repo/blob/main", text: $gitHubBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("GitHub folder URL")
                } footer: {
                    Text("The URL of the uploaded test-file folder. The file screen adds the file path to it. Empty hides the GitHub button.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
