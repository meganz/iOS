import SwiftUI

struct CallsSettingsSoundNotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var isOn: Bool
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                Toggle(Strings.Localizable.Settings.Section.Calls.SoundNotifications.title, isOn: $isOn)
                    .padding(.horizontal)
                Divider()
            }
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            Text(Strings.Localizable.Settings.Section.Calls.SoundNotifications.description)
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.54) : .black.opacity(0.54))
        }
    }
}
