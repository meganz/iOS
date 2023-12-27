import SwiftUI

struct CallsSettingsView: View {
    @State var viewModel: CallsSettingsViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                CallsSettingsSoundNotificationsView(isOn: $viewModel.callsSoundNotificationPreference, parentGeometry: geometry)
            }
            .edgesIgnoringSafeArea(.horizontal)
            .padding(.top)
            .background(colorScheme == .dark ? MEGAAppColor.Black._000000.color.edgesIgnoringSafeArea([.horizontal, .bottom]) : MEGAAppColor.White._F7F7F7.color.edgesIgnoringSafeArea([.horizontal, .bottom])
)        }
    }
}
