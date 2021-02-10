import Foundation

extension CustomModalAlertViewController {
    func configureForCookieDialog() {
        image = UIImage(named: "cookie")
        viewTitle = NSLocalizedString("Before You Continue", comment: "")
        detailAttributed = detailTextAttributedString()
        
        let detailTapGR = UITapGestureRecognizer(target: self, action: #selector(cookiePolicyTouchUpInside))
        detailTapGR.cancelsTouchesInView = false
        detailTapGestureRecognizer = detailTapGR
        
        firstButtonTitle = NSLocalizedString("Accept Cookies", comment: "")
        dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
        dismissButtonTitle = NSLocalizedString("Cookie Settings", comment: "")
        
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
        var detailText = NSLocalizedString("Cookie dialog text -- We use Cookies and similar technologies (‘Cookies’)...", comment: "") as NSString
        let cookiePolicy = detailText.mnz_stringBetweenString("[A]", andString: "[/A]")
        detailText = detailText.mnz_removeWebclientFormatters() as NSString
        
        let cookiePolicyRange = detailText.range(of: cookiePolicy ?? "")
        let detailTextAttributedString = NSMutableAttributedString(string: detailText as String, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .medium), NSAttributedString.Key.foregroundColor : UIColor.mnz_subtitles(for: traitCollection)])
        detailTextAttributedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.mnz_turquoise(for: traitCollection)], range: cookiePolicyRange)
        
        return detailTextAttributedString
    }
    
    @IBAction func cookiePolicyTouchUpInside(_ sender: UITapGestureRecognizer) {
        NSURL.init(string: "https://mega.nz/cookie")?.mnz_presentSafariViewController()
    }
}
