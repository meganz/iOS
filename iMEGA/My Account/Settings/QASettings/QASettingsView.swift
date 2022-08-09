import SwiftUI

struct QASettingsView: View {
    
    enum Constants {
        static let appUpdatesHeaderText = "APP UPDATES"
        static let featureListHeaderText = "FEATURE LIST"
        static let checkForUpdateText = "Check for updates"
        static let cellDarkBackgroundColor = Color(Colors.General.Black._1c1c1e.name)
        static let cellLightBackgroundColor = Color.white
    }
    
    let viewModel: QASettingsViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            Section(header: Text(Constants.appUpdatesHeaderText)) {
                Button {
                    viewModel.checkForUpdate()
                } label: {
                    Text(Constants.checkForUpdateText)
                }
                .listRowBackground(listRowBackgroundColor)
            }            
            
            Section(header: Text(Constants.featureListHeaderText)) {
                ForEach(viewModel.featureToggleList) { featureToggle in
                    FeatureToggleView(featureToggle: featureToggle)
                        .listRowInsets(.init())
                }
                .listRowBackground(listRowBackgroundColor)
            }
        }
        .listStyle(.plain)
        .padding(.top)
        .background(backgroundColor)
    }
    
    private var listRowBackgroundColor: Color {
        colorScheme == .dark ? Constants.cellDarkBackgroundColor : Constants.cellLightBackgroundColor
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name)
    }
}


struct FeatureToggleView: View {
    @ObservedObject var featureToggle: FeatureToggle
    
    var body: some View {
        Toggle(featureToggle.name, isOn: $featureToggle.isEnabled)
            .padding(.horizontal)
            .padding(.vertical, 5)
    }
}
