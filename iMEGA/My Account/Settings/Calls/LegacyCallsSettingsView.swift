import MEGADesignToken
import MEGAPresentation
import SwiftUI

struct LegacyCallsSettingsView: View {
    @State var viewModel: CallsSettingsViewModel
    
    private var backgroundView: some View {
        TokenColors.Background.page.swiftUI.edgesIgnoringSafeArea([.horizontal, .bottom])
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                CallsSettingsSoundNotificationsView(isOn: $viewModel.callsSoundNotificationPreference, parentGeometry: geometry)
            }
            .edgesIgnoringSafeArea(.horizontal)
            .padding(.top)
            .background(backgroundView)
        }
    }
}
