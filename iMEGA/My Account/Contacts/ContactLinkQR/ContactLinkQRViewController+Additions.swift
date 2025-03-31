import MEGADesignToken
import MEGAL10n
import UIKit

extension ContactLinkQRViewController {
    
    @objc func updateAppearance(_ segmentControl: MEGASegmentedControl) {
        switch segmentControl.selectedSegmentIndex {
        case QRSection.myCode.rawValue:
            view.backgroundColor = TokenColors.Background.page
            backButton?.tintColor = TokenColors.Button.primary
            moreButton?.tintColor = TokenColors.Icon.primary
            
            // The SVProgressHUD appearance is not updated when enabling/disabling dark mode.
            // By updating the appearance and dismissing the HUD, it will have the correct configuration the next time is shown.
            AppearanceManager.configureSVProgressHUD()
            SVProgressHUD.dismiss()
            
        case QRSection.scanCode.rawValue:
            view.backgroundColor = TokenColors.Background.blur
            backButton?.tintColor = TokenColors.Icon.onColor
            hintLabel?.textColor = TokenColors.Text.onColor
        default:
            break
        }
        
        setupSegmentControl(segmentControl)
        setupQRImage(from: contactLinkLabel?.text ?? "")

        errorLabel?.textColor = TokenColors.Text.onColor
        linkCopyButton?.mnz_setupPrimary()
    }

    private func setupSegmentControl(_ segmentControl: MEGASegmentedControl) {
        switch segmentControl.selectedSegmentIndex {
        case QRSection.myCode.rawValue:
            segmentControl.setTitleTextColor(TokenColors.Text.primary, selectedColor: TokenColors.Text.primary)
        case QRSection.scanCode.rawValue:
            segmentControl.setTitleTextColor(TokenColors.Text.onColor, selectedColor: TokenColors.Text.primary)
        default:
            break
        }
    }
    
    @objc func setupQRImage(from text: String) {
        qrImageView?.image = UIImage.mnz_qrImage(
            from: text,
            with: qrImageView?.frame.size ?? .zero,
            color: TokenColors.Icon.primary,
            backgroundColor: TokenColors.Background.page
        )
    }

    @objc func feedback(success: Bool) {
        let message = success ? Strings.Localizable.codeScanned : Strings.Localizable.invalidCode
        let color = success ? TokenColors.Support.success : TokenColors.Support.error
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            errorLabel?.text = message
            
            let colorAnimation = CABasicAnimation(keyPath: "borderColor")
            colorAnimation.fromValue = color.cgColor
            colorAnimation.toValue = TokenColors.Border.strong
            colorAnimation.duration = 1
            cameraMaskBorderView?.layer.add(colorAnimation, forKey: "borderColor")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            
            queryInProgress = success // If success, queryInProgress will be NO later
            errorLabel?.text = ""
        }
    }
}
