import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGAUIComponent
import SwiftUI

struct CallsSettingsView: View {
    @StateObject var viewModel: CallsSettingsViewModel
    
    var body: some View {
        ScrollView {
            MEGAList(
                title: Strings.Localizable.Settings.Section.Calls.SoundNotifications.title,
                subtitle: Strings.Localizable.Settings.Section.Calls.SoundNotifications.description
            ).replaceTrailingView {
                MEGAToggle(state: .init(isOn: viewModel.isEnabled ?? false)) { state in
                    viewModel.toggle(state != .on)
                }
            }
            .edgesIgnoringSafeArea(.horizontal)
            .padding(.top)
        }
    }
}
