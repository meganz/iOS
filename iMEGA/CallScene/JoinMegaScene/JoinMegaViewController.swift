import UIKit

class JoinMegaViewController: UIViewController {
    
    // MARK: - Internal properties
    private let viewModel: JoinMegaViewModel
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var paragraph1TitleLabel: UILabel!
    @IBOutlet private weak var paragraph1SubtitleLabel: UILabel!
    @IBOutlet private weak var paragraph2TitleLabel: UILabel!
    @IBOutlet private weak var paragraph2SubtitleLabel: UILabel!
    @IBOutlet private weak var joinButton: UIButton!

    init(viewModel: JoinMegaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Join MEGA", comment: "")
        view.backgroundColor = .mnz_background()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("close", comment: ""),
            style: .plain,
            target: self,
            action: #selector(dissmissVC(_:))
        )
        
        joinButton.setTitle(NSLocalizedString("createAccount", comment: ""), for: .normal)
        joinButton.mnz_setupPrimary(traitCollection)
        
        paragraph1TitleLabel.text = NSLocalizedString("meetings.joinMega.paragraph1.title", comment: "")
        paragraph1SubtitleLabel.text = NSLocalizedString("meetings.joinMega.paragraph1.description", comment: "")

        paragraph2TitleLabel.text = NSLocalizedString("meetings.joinMega.paragraph2.title", comment: "")
        paragraph2SubtitleLabel.text = NSLocalizedString("meetings.joinMega.paragraph2.description", comment: "")
    }
    
    @objc private func dissmissVC(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.didTapCloseButton)
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        viewModel.dispatch(.didCreateAccountButton)
    }
}
