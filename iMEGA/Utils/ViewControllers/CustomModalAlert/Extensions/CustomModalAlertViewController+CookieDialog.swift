import Foundation

extension CustomModalAlertViewController {
    func configureForCookieDialog() {
        image = UIImage(named: "cookie")
        viewTitle = Strings.Localizable.beforeYouContinue
        detailAttributed = detailTextAttributedString()
        
        let detailTapGR = UITapGestureRecognizer(target: self, action: #selector(cookiePolicyTouchUpInside))
        detailTapGR.cancelsTouchesInView = false
        detailTapGestureRecognizer = detailTapGR
        
        firstButtonTitle = Strings.Localizable.acceptCookies
        dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
        dismissButtonTitle = Strings.Localizable.cookieSettings
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository(sdk: MEGASdkManager.sharedMEGASdk()))
                cookieSettingsUseCase.setCookieSettings(with: CookiesBitmap.all.rawValue) { [weak self] in
                    switch $0 {
                    case .success(_):
                        self?.dismiss(animated: true, completion: nil)
                        
                    case .failure(let error):
                        switch error {
                        case .invalidBitmap:
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                            
                        default:
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                        }
                    }
                }
            })
        }
        
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                let cookieSettingsFactory = CookieSettingsFactory()
                let cookieSettingsNC = cookieSettingsFactory.createCookieSettingsNC()
                
                if UIApplication.mnz_presentingViewController().presentedViewController == nil {
                    UIApplication.mnz_visibleViewController().navigationController?.present(cookieSettingsNC, animated: true, completion: nil)
                } else {
                    UIApplication.mnz_presentingViewController().navigationController?.present(cookieSettingsNC, animated: true, completion: nil)
                }
            })
        }
    }
    
    @objc func detailTextAttributedString() -> NSAttributedString {
        var detailText = Strings.Localizable.cookieDialogTextWeUseCookiesAndSimilarTechnologiesCookies as NSString
        let cookiePolicy = detailText.mnz_stringBetweenString("[A]", andString: "[/A]")
        detailText = detailText.mnz_removeWebclientFormatters() as NSString
        
        let cookiePolicyRange = detailText.range(of: cookiePolicy ?? "")
        let detailTextAttributedString = NSMutableAttributedString(string: detailText as String, attributes: [NSAttributedString.Key.font : UIFont.preferredFont(style: .footnote, weight: .medium), NSAttributedString.Key.foregroundColor : UIColor.mnz_subtitles(for: traitCollection)])
        detailTextAttributedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.mnz_turquoise(for: traitCollection)], range: cookiePolicyRange)
        
        return detailTextAttributedString
    }
    
    @IBAction func cookiePolicyTouchUpInside(_ sender: UITapGestureRecognizer) {
        NSURL.init(string: "https://mega.nz/cookie")?.mnz_presentSafariViewController()
    }
}
