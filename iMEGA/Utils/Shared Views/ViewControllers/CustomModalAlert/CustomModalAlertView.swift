import Foundation
import MEGADomain
import SwiftUI

struct CustomModalAlertView: UIViewControllerRepresentable {
        
    private let mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    func makeUIViewController(context: Context) -> CustomModalAlertViewController {
        let controller = CustomModalAlertViewController()
        switch mode {
        case .businessGracePeriod:
            controller.configureForBusinessGracePeriod()
        case .enableKeyRotation(let chatId):
            controller.configureForEnableKeyRotation(in: chatId)
        case .upgradeSecurity:
            controller.configureForUpgradeSecurity()
        case .pendingUnverifiedOutShare(let outShareEmail):
            controller.configureForPendingUnverifiedOutshare(for: outShareEmail)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CustomModalAlertViewController, context: Context) { }
    
}

extension CustomModalAlertView {
    
    enum Mode {
        case businessGracePeriod
        case enableKeyRotation(chatId: ChatIdEntity)
        case upgradeSecurity
        case pendingUnverifiedOutShare(outShareEmail: String)
    }
}

#Preview {
    CustomModalAlertView(mode: .upgradeSecurity)
}
