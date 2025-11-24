import MEGAAppPresentation
import MEGADesignToken
import SwiftUI

struct LegacyCallsSettingsView: View {
    @State var viewModel: CallsSettingsViewModel
    
    private var backgroundView: some View {
        TokenColors.Background.page.swiftUI.edgesIgnoringSafeArea([.horizontal, .bottom])
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
                    contentView(geometry: geometry)
                } else {
                    contentView(geometry: geometry)
                        .padding(.top)
                }
            }
            .background(backgroundView)
        }
    }

    private func contentView(geometry: GeometryProxy) -> some View {
        ScrollView {
            CallsSettingsSoundNotificationsView(isOn: $viewModel.callsSoundNotificationPreference, parentGeometry: geometry)
        }
        .edgesIgnoringSafeArea(.horizontal)
    }
}
