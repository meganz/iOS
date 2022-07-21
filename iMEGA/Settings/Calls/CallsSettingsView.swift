import SwiftUI

struct CallsSettingsView: View {
    @State var viewModel: CallsSettingsViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            CallsSettingsSoundNotificationsView(isOn: $viewModel.callsSoundNotificationPreference)
        }
        .padding(.top)
        .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))
    }
}
