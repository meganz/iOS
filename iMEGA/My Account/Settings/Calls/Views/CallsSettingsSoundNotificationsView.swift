import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct CallsSettingsSoundNotificationsView: View {
    @Binding var isOn: Bool
    var parentGeometry: GeometryProxy
    
    private enum Constants {
        static let defaultPadding: CGFloat = 16
        static let textDescriptionOpacity: CGFloat = 0.54
    }
    
    var body: some View {
        VStack {
            VStack {
                MEGADivider()
                Toggle(Strings.Localizable.Settings.Section.Calls.SoundNotifications.title, isOn: $isOn)
                    .padding(.leading, parentGeometry.safeAreaInsets.leading + Constants.defaultPadding)
                    .padding(.trailing, parentGeometry.safeAreaInsets.trailing + Constants.defaultPadding)
                    .toggleBackground()
                MEGADivider()
            }
            .background(TokenColors.Background.page.swiftUI)
            Text(Strings.Localizable.Settings.Section.Calls.SoundNotifications.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, parentGeometry.safeAreaInsets.leading + Constants.defaultPadding)
                .padding(.trailing, parentGeometry.safeAreaInsets.trailing + Constants.defaultPadding)
                .font(.footnote)
                .foregroundColor(TokenColors.Text.secondary.swiftUI)
        }
    }
}
