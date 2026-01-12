import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct LimitedAccessBannerView: View {
    @State private var showPermissionAlert = false
    var closeButtonAction: () -> Void
    
    var body: some View {
        MEGABanner(
            subtitle: Strings.Localizable.CameraUploads.Progress.Banner.LimitedAccess.subtitle,
            buttonText: Strings.Localizable.CameraUploads.Progress.Banner.LimitedAccess.Button.title,
            state: .warning,
            buttonAction: {
                showPermissionAlert = true
            },
            closeButtonAction: closeButtonAction
        )
        .alert(
            Strings.Localizable.attention,
            isPresented: $showPermissionAlert
        ) {
            Button(role: .cancel) {
                
            } label: {
                Text(Strings.Localizable.notNow)
            }
            
            Button(Strings.Localizable.settingsTitle) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(url)
            }
        } message: {
            Text(Strings.Localizable.photoLibraryPermissions)
        }
    }
}
