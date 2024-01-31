import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct CallsSettingsSoundNotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var isOn: Bool
    var parentGeometry: GeometryProxy
    
    private enum Constants {
        static let defaultPadding: CGFloat = 16
        static let textDescriptionOpacity: CGFloat = 0.54
    }
    
    private var backgroundColor: Color {
        isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : colorScheme == .dark ? Color(.black1C1C1E) : .white
    }
    
    private var textForegroundColor: Color {
        isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : colorScheme == .dark ?
            .white.opacity(Constants.textDescriptionOpacity) : .black.opacity(Constants.textDescriptionOpacity)
    }
    
    var body: some View {
        VStack {
            VStack {
                MEGADivider(isDesignTokenEnabled: isDesignTokenEnabled)
                Toggle(Strings.Localizable.Settings.Section.Calls.SoundNotifications.title, isOn: $isOn)
                    .padding(.leading, parentGeometry.safeAreaInsets.leading + Constants.defaultPadding)
                    .padding(.trailing, parentGeometry.safeAreaInsets.trailing + Constants.defaultPadding)
                    .designTokenToggleBackground(isDesignTokenEnabled)
                MEGADivider(isDesignTokenEnabled: isDesignTokenEnabled)
            }
            .background(backgroundColor)
            Text(Strings.Localizable.Settings.Section.Calls.SoundNotifications.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, parentGeometry.safeAreaInsets.leading + Constants.defaultPadding)
                .padding(.trailing, parentGeometry.safeAreaInsets.trailing + Constants.defaultPadding)
                .font(.footnote)
                .foregroundColor(textForegroundColor)
        }
    }
}
