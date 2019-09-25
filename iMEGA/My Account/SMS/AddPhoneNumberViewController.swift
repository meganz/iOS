
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
        MEGASdkManager.sharedMEGASdk()?.getAccountAchievements(with: MEGAGenericRequestDelegate() { [weak self] request, error in
            guard error.type == .apiOk else { return }
            guard let byteCount = request.megaAchievementsDetails?.classStorage(forClassId: Int(MEGAAchievement.addPhone.rawValue)) else { return }
            self?.descriptionLabel.text = String(format: AMLocalizedString("Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA."), Helper.memoryStyleString(fromByteCount: byteCount))
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber {
           dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - UI Actions
    
    @IBAction func didTapAddPhoneNumberButton() {
        present(SMSNavigationViewController(rootViewController: SMSVerificationViewController.instantiate(with: .AddPhoneNumber)), animated: true, completion: nil)
    }
    
    @IBAction func didTapNotNowButton() {
        dismiss(animated: true, completion: nil)
    }
}
