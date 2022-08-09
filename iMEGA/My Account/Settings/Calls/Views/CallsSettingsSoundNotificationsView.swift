import SwiftUI

struct CallsSettingsSoundNotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var isOn: Bool
    var parentGeometry: GeometryProxy

    private enum Constants {
        static let defaultPadding: CGFloat = 16
        static let textDescriptionOpacity: CGFloat = 0.54
    }
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                Toggle(Strings.Localizable.Settings.Section.Calls.SoundNotifications.title, isOn: $isOn)
                    .padding(.leading, parentGeometry.safeAreaInsets.leading + Constants.defaultPadding)
                    .padding(.trailing, parentGeometry.safeAreaInsets.trailing + Constants.defaultPadding)
                Divider()
            }
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            Text(Strings.Localizable.Settings.Section.Calls.SoundNotifications.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, parentGeometry.safeAreaInsets.leading + Constants.defaultPadding)
                .padding(.trailing, parentGeometry.safeAreaInsets.trailing + Constants.defaultPadding)
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? .white.opacity(Constants.textDescriptionOpacity) : .black.opacity(Constants.textDescriptionOpacity))
        }
    }
}
