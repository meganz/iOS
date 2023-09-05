import Foundation
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct PermissionAlertViewModifier: ViewModifier {
    
    let isPresented: Binding<Bool>
    let viewModel: PermissionAlertModel
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: isPresented) {
                if let secondaryAction = viewModel.secondaryAction {
                    return Alert(title: Text(viewModel.title),
                          message: Text(viewModel.message),
                          primaryButton: alertButton(for: viewModel.primaryAction),
                          secondaryButton: alertButton(for: secondaryAction))
                          
                } else {
                    return Alert(title: Text(viewModel.title),
                          message: Text(viewModel.message),
                          dismissButton: .cancel(Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.dissmissButtonTitle)))
                }
            }
    }
    
    private func alertButton(for action: PermissionAlertModel.ActionModel) -> Alert.Button {
        switch action.style {
        case .default:
            return .default(Text(action.title), action: action.handler)
        case .cancel:
            return .cancel(Text(action.title), action: action.handler)
        case .destructive:
            return .destructive(Text(action.title), action: action.handler)
        }
    }
}

extension View {
    
    func alertPhotosPermission(isPresented: Binding<Bool>) -> some View {
        permissionAlert(isPresented: isPresented, viewModel: .photo(completion: openSettings))
    }
    
    func alertVideoPermission(isPresented: Binding<Bool>) -> some View {
        permissionAlert(isPresented: isPresented, viewModel: .video(completion: openSettings))
    }
    
    private var openSettings: () -> Void {
        {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(url)
        }
    }
    
    private func permissionAlert(isPresented: Binding<Bool>, viewModel: PermissionAlertModel) -> some View {
        modifier(PermissionAlertViewModifier(
            isPresented: isPresented,
            viewModel: viewModel))
    }
}
