
import UIKit

class AddPhoneNumberViewController: UIViewController {
    
    @IBOutlet private weak var addPhoneNumberButton: UIButton!
    @IBOutlet private weak var nowNowButton: UIButton!
    @IBOutlet private weak var addPhoneNumberTitle: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - UI Actions
    
    @IBAction func didTapAddPhoneNumberButton() {
        present(SMSNavigationViewController(rootViewController: SMSVerificationViewController.instantiate(with: .AddPhoneNumber)), animated: true, completion: nil)
    }
    
    @IBAction func didTapNotNowButton() {
        dismiss(animated: true, completion: nil)
    }
}
