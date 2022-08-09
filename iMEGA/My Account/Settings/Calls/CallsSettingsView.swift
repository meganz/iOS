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
            .background(colorScheme == .dark ? Color.black.edgesIgnoringSafeArea([.horizontal, .bottom]) : Color(Colors.General.White.f7F7F7.name).edgesIgnoringSafeArea([.horizontal, .bottom]))
        }
    }
}
