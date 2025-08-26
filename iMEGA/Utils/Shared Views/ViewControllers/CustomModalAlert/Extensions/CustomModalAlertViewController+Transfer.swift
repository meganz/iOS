import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift

extension CustomModalAlertViewController {
    typealias TransferQuotaErrorMode = CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode
    
    // MARK: - Public
    func configureForTransferQuotaError(
        for displayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode,
        actionHandler: ((@escaping () -> Void) -> Void)? = nil,
        dismissHandler: (() -> Void)? = nil
    ) {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        image = transferDialogImage(for: displayMode)
        viewTitle = transferDialogTitle(for: displayMode)
        
        if accountUseCase.isLoggedIn() {
            guard let accountDetails = accountUseCase.currentAccountDetails else {
                MEGALogDebug("[Transfer Quota Dialog] No user account details")
                return
            }
            if accountDetails.proLevel == .free {
                setTransferQuotaDetailWithCountdown(duration: Int(accountUseCase.bandwidthOverquotaDelay),
                                       displayMode: displayMode)
                
                firstButtonTitle = Strings.Localizable.TransferQuotaError.Button.upgrade
                dismissButtonTitle = Strings.Localizable.TransferQuotaError.Button.wait
                dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
            } else {
                detail = proAccountMessage(accountDetails: accountDetails, displayMode: displayMode)
                firstButtonTitle = Strings.Localizable.TransferQuotaError.Button.buyNewPlan
                dismissButtonTitle = Strings.Localizable.dismiss
                dismissButtonStyle = MEGACustomButtonStyle.none.rawValue
            }
            
            firstCompletion = { [weak self] in
                guard let self else { return }
                dismiss(animated: true) {
                    let showUpgrade = {
                        SubscriptionPurchaseRouter(
                            presenter: UIApplication.mnz_visibleViewController(),
                            currentAccountDetails: accountDetails,
                            viewType: .upgrade,
                            accountUseCase: AccountUseCase(
                                repository: AccountRepository.newRepo),
                            isFromAds: false)
                        .start()
                    }
                    if let actionHandler {
                        actionHandler {
                            showUpgrade()
                        }
                    } else {
                        showUpgrade()
                    }
                }
            }
            
            dismissCompletion = { [weak self] in
                guard let self else { return }
                dismiss(animated: true) {
                    dismissHandler?()
                }
            }
        } else {
            setTransferQuotaDetailWithCountdown(duration: Int(accountUseCase.bandwidthOverquotaDelay),
                                   displayMode: displayMode)
            
            firstButtonTitle = Strings.Localizable.login
            dismissButtonTitle = Strings.Localizable.TransferQuotaError.Button.wait
            dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
            
            firstCompletion = { [weak self] in
                guard let self else { return }
                dismiss(animated: true) {
                    self.presentLogin()
                }
            }
        }
        
        dismissButtonStyle = MEGACustomButtonStyle.none.rawValue
        
        viewModel = .init(tracker: DIContainer.tracker,
                          analyticsEvents: .init(dialogDisplayedEventIdentifier: DIContainer.transferOverQuotaDialogEvent,
                                                 fistButtonPressedEventIdentifier: DIContainer.transferOverQuotaUpgradeAccountButtonEvent))
    }
    
    private func setTransferQuotaDetailWithCountdown(
        duration: Int,
        displayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode
    ) {
        detailAttributedTextWithLink = freeAccountAttributedMessage(
            delayDuration: duration,
            displayMode: displayMode
        )

        countdownTimer = CountdownTimer()
        countdownTimer.startCountdown(seconds: duration) { [weak self] newDuration in
            guard let self else { return }
            updateDetailAttributedTextWithLink(freeAccountAttributedMessage(
                delayDuration: newDuration,
                displayMode: displayMode
            ))
        }
    }
    
    // MARK: - Private
    
    private func transferDialogTitle(for displayMode: TransferQuotaErrorMode) -> String {
        switch displayMode {
        case .limitedDownload:
            return Strings.Localizable.TransferQuotaError.DownloadLimitedQuota.title
        case .downloadExceeded, .streamingExceeded:
            return Strings.Localizable.TransferQuotaError.DownloadExceededQuota.title
        }
    }
    
    private func transferDialogImage(for displayMode: TransferQuotaErrorMode) -> UIImage {
        switch displayMode {
        case .limitedDownload:
            return MEGAAssets.UIImage.transferLimitedQuota
        case .downloadExceeded, .streamingExceeded:
            return MEGAAssets.UIImage.transferExceededQuota
        }
    }
    
    private func freeAccountAttributedMessage(
        delayDuration: Int,
        displayMode: TransferQuotaErrorMode
    ) -> NSAttributedString {
        let (durationString, tappableString, fullMessage) = freeAccountMessage(delayDuration: delayDuration,
                                                                               displayMode: displayMode)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let regularAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label,
                                 NSAttributedString.Key.font: UIFont.preferredFont(style: .subheadline, weight: .regular),
                                 NSAttributedString.Key.paragraphStyle: paragraph]
        let delayAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(style: .subheadline, weight: .bold)]
        
        let attributedString = NSMutableAttributedString(string: fullMessage, attributes: regularAttributes)
        let delayRange = NSString(string: fullMessage).range(of: durationString)
        attributedString.addAttributes(delayAttributes, range: delayRange)
        
        guard let urlLink = URL(string: "https://help.mega.io/plans-storage/space-storage/transfer-quota") else {
            return attributedString
        }
        let urlRange = NSString(string: fullMessage).range(of: tappableString)
        let foregroundColor = TokenColors.Link.primary
        attributedString.addAttributes([.foregroundColor: foregroundColor, .link: urlLink], range: urlRange)
        
        return attributedString
    }
    
    private func delayDurationString(delayDuration: Int) -> String? {
        guard delayDuration >= 60 else {
            return delayDuration.string(allowedUnits: [.second], unitStyle: .abbreviated)
        }
        
        guard delayDuration >= 3600 else {
            return delayDuration.string(allowedUnits: [.minute, .second], unitStyle: .abbreviated)
        }
        
        return delayDuration.string(allowedUnits: [.hour, .minute, .second], unitStyle: .abbreviated)
    }
    
    private func freeAccountMessage(
        delayDuration: Int,
        displayMode: TransferQuotaErrorMode
    ) -> (durationString: String, tappableString: String, fullMessage: String) {
        
        let durationString = delayDurationString(delayDuration: delayDuration) ?? "0s"
        var details: String
        switch displayMode {
        case .limitedDownload:
            details = Strings.Localizable.TransferQuotaError.DownloadLimitedQuota.FreeAccount.message(durationString)
        case .downloadExceeded:
            details = Strings.Localizable.TransferQuotaError.DownloadExceededQuota.FreeAccount.message(durationString)
        case .streamingExceeded:
            details = Strings.Localizable.TransferQuotaError.StreamingExceededQuota.FreeAccount.message(durationString)
        }
        
        let tappableString = details.subString(from: "[A]", to: "[/A]") ?? ""
        let fullTextWithoutFormatters = details
            .replacingOccurrences(of: "[A]", with: "")
            .replacingOccurrences(of: "[/A]", with: "")
        return (durationString, tappableString, fullTextWithoutFormatters)
    }
    
    private func proAccountMessage(
        accountDetails: AccountDetailsEntity,
        displayMode: TransferQuotaErrorMode
    ) -> String {
        
        var details: String
        switch displayMode {
        case .limitedDownload:
            details = Strings.Localizable.TransferQuotaError.DownloadLimitedQuota.ProAccount.message
        case .downloadExceeded:
            details = Strings.Localizable.TransferQuotaError.DownloadExceededQuota.ProAccount.message
        case .streamingExceeded:
            details = Strings.Localizable.TransferQuotaError.StreamingExceededQuota.ProAccount.message
        }
        
        let maxQuota = accountDetails.transferMax
        let usedTransferPercent = (Float(accountDetails.transferUsed) / Float(maxQuota)) * 100
        let formattedMaxQuota = String.memoryStyleString(fromByteCount: Int64(maxQuota), includesUnit: false)
        
        let usageText = Strings.Localizable.TransferQuotaError.FooterMessage.quotaUsage
            .replacingOccurrences(of: "[A]", with: String(format: "%.0f", usedTransferPercent))
            .replacingOccurrences(of: "[B]", with: formattedMaxQuota)

        details.append("\n\n\(usageText)")
        return details
    }

    private func presentLogin() {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp) {
            LoginViewRouter(presenter: UIApplication.mnz_presentingViewController())
                .start()
        } else {
            let loginNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginNavigationControllerID")
            loginNC.modalPresentationStyle = .fullScreen
            
            UIApplication.mnz_presentingViewController().present(loginNC, animated: true)
        }
    }
}
