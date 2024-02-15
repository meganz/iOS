import MEGADesignToken
import MEGAL10n
import UIKit

extension ContactLinkQRViewController {
    
    @objc func updateAppearance(_ segmentControl: MEGASegmentedControl) {
        switch segmentControl.selectedSegmentIndex {
        case QRSection.myCode.rawValue:
            view.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_backgroundElevated(traitCollection)
            backButton?.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Button.primary : UIColor.mnz_primaryGray(for: traitCollection)
            moreButton?.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Icon.primary : UIColor.mnz_primaryGray(for: traitCollection)
            
            // The SVProgressHUD appearance is not updated when enabling/disabling dark mode.
            // By updating the appearance and dismissing the HUD, it will have the correct configuration the next time is shown.
            AppearanceManager.configureSVProgressHUD(traitCollection)
            SVProgressHUD.dismiss()
            
        case QRSection.scanCode.rawValue:
            view.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.blur : .clear
            backButton?.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Icon.onColor : UIColor.mnz_whiteFFFFFF()
            hintLabel?.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.onColor : UIColor.mnz_whiteFFFFFF()
        default:
            break
        }
        
        setupSegmentControl(segmentControl)
        setupQRImage(from: contactLinkLabel?.text ?? "")

        errorLabel?.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.onColor : .white
        linkCopyButton?.mnz_setupPrimary(traitCollection)
    }

    private func setupSegmentControl(_ segmentControl: MEGASegmentedControl) {
        switch segmentControl.selectedSegmentIndex {
        case QRSection.myCode.rawValue:
            if UIColor.isDesignTokenEnabled() {
                segmentControl.setTitleTextColor(TokenColors.Text.primary, selectedColor: TokenColors.Text.primary)
            } else {
                segmentControl.setTitleTextColor(UIColor.label, selectedColor: UIColor.label)
            }
        case QRSection.scanCode.rawValue:
            if UIColor.isDesignTokenEnabled() {
                segmentControl.setTitleTextColor(TokenColors.Text.onColor, selectedColor: TokenColors.Text.primary)
            } else {
                let scanCodeTextColor = traitCollection.userInterfaceStyle == .dark ? UIColor.mnz_whiteFFFFFF() : MEGAAppColor.Black._000000.uiColor
                segmentControl.setTitleTextColor(UIColor.mnz_whiteFFFFFF(), selectedColor: scanCodeTextColor)
            }
        default:
            break
        }
    }
    
    @objc func setupQRImage(from text: String) {
        let color = UIColor.isDesignTokenEnabled() ? TokenColors.Icon.primary : UIColor.mnz_qr(traitCollection)
        let backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_secondaryBackground(for: traitCollection)
        
        qrImageView?.image = UIImage.mnz_qrImage(
            from: text,
            with: qrImageView?.frame.size ?? .zero,
            color: color,
            backgroundColor: backgroundColor
        )
    }

    @objc func feedback(success: Bool) {
        let message = success ? Strings.Localizable.codeScanned : Strings.Localizable.invalidCode
        
        var color = success ? UIColor.mnz_green00FF00() : UIColor.mnz_redFF0000()
        
        if UIColor.isDesignTokenEnabled() {
            color = success ? TokenColors.Support.success : TokenColors.Support.error
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            errorLabel?.text = message
            
            let colorAnimation = CABasicAnimation(keyPath: "borderColor")
            colorAnimation.fromValue = color.cgColor
            colorAnimation.toValue = UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : UIColor.mnz_whiteFFFFFF().cgColor
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
