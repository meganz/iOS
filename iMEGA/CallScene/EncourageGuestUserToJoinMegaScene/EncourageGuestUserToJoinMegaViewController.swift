import MEGAL10n
import UIKit

class EncourageGuestUserToJoinMegaViewController: UIViewController {
    
    // MARK: - Internal properties
    private let viewModel: EncourageGuestUserToJoinMegaViewModel
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var paragraph1TitleLabel: UILabel!
    @IBOutlet private weak var paragraph1SubtitleLabel: UILabel!
    @IBOutlet private weak var paragraph2TitleLabel: UILabel!
    @IBOutlet private weak var paragraph2SubtitleLabel: UILabel!
    @IBOutlet private weak var createAccountButton: UIButton!
    
    init(viewModel: EncourageGuestUserToJoinMegaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Localizable.Meetings.JoinMega.title
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.close,
            style: .plain,
            target: self,
            action: #selector(dismissVC(_:))
        )
        
        createAccountButton.setTitle(Strings.Localizable.createAccount, for: .normal)
        createAccountButton.mnz_setupPrimary()
        
        paragraph1TitleLabel.text = Strings.Localizable.Meetings.JoinMega.Paragraph1.title
        paragraph1SubtitleLabel.text = Strings.Localizable.Meetings.JoinMega.Paragraph1.description

        paragraph2TitleLabel.text = Strings.Localizable.Meetings.JoinMega.Paragraph2.title
        paragraph2SubtitleLabel.text = Strings.Localizable.Meetings.JoinMega.Paragraph2.description
    }
    
    @objc private func dismissVC(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.didTapCloseButton)
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        viewModel.dispatch(.didCreateAccountButton)
    }
}
