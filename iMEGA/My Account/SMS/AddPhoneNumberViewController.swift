import UIKit

class AddPhoneNumberViewController: UIViewController {

    @IBOutlet private weak var addPhoneNumberButton: UIButton!
    @IBOutlet private weak var notNowButton: UIButton!
    @IBOutlet private weak var addPhoneNumberTitle: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        addPhoneNumberButton.setTitle(AMLocalizedString("Add Phone Number"), for: .normal)
        notNowButton.setTitle(AMLocalizedString("notNow"), for: .normal)
        addPhoneNumberTitle.text = AMLocalizedString("Add Phone Number")
        if !MEGASdkManager.sharedMEGASdk().isAchievementsEnabled {
            descriptionLabel.text = AMLocalizedString("Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.")
        } else {
            MEGASdkManager.sharedMEGASdk()?.getAccountAchievements(with: MEGAGenericRequestDelegate { [weak self] request, error in
                guard error.type == .apiOk else { return }
                guard let byteCount = request.megaAchievementsDetails?.classStorage(forClassId: Int(MEGAAchievement.addPhone.rawValue)) else { return }
                self?.descriptionLabel.text = String(format: AMLocalizedString("Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA."), Helper.memoryStyleString(fromByteCount: byteCount))
            })
        }
        
        updateAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() != nil {
           dismiss(animated: true, completion: nil)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        
        addPhoneNumberButton.mnz_setupPrimary(traitCollection)
        notNowButton.mnz_setupCancel(traitCollection)
    }
    
    // MARK: - UI Actions

    @IBAction func didTapAddPhoneNumberButton() {
        dismiss(animated: true) {
            let smsNavigation = SMSNavigationViewController(rootViewController: SMSVerificationViewController.instantiate(with: .AddPhoneNumber))
            UIApplication.mnz_visibleViewController().present(smsNavigation, animated: true, completion: nil)
        }
    }

    @IBAction func didTapNotNowButton() {
        dismiss(animated: true, completion: nil)
    }
}
