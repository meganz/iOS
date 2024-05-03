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
        case .storageQuotaError:
            controller.configureForStorageQuotaError(false)
        case .storageUploadQuotaError:
            controller.configureForStorageQuotaError(true)
        case .transferQuotaError(let displayMode):
            controller.configureForTransferQuotaError(for: displayMode)
        case .businessGracePeriod:
            controller.configureForBusinessGracePeriod()
        case .enableKeyRotation(let chatId):
            controller.configureForEnableKeyRotation(in: chatId)
        case .upgradeSecurity:
            controller.configureForUpgradeSecurity()
        case .pendingUnverifiedOutShare(let outShareEmail):
            controller.configureForPendingUnverifiedOutshare(for: outShareEmail)
        case .storageQuotaWillExceed(let displayMode):
            controller.configureForStorageQuotaWillExceed(for: displayMode)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CustomModalAlertViewController, context: Context) { }
    
}

extension CustomModalAlertView {
    
    enum Mode {
        case storageQuotaError
        case storageUploadQuotaError
        case transferQuotaError(displayMode: TransferQuotaErrorDisplayMode)
        case businessGracePeriod
        case enableKeyRotation(chatId: ChatIdEntity)
        case upgradeSecurity
        case pendingUnverifiedOutShare(outShareEmail: String)
        case storageQuotaWillExceed(displayMode: StorageQuotaWillExceedDisplayMode)
        
        enum StorageQuotaWillExceedDisplayMode {
            case albumLink
        }
        
        enum TransferQuotaErrorDisplayMode {
            case limitedDownload, downloadExceeded, streamingExceeded
        }
    }
}

#Preview {
    CustomModalAlertView(mode: .storageQuotaError)
}
