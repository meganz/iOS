import UIKit

final class AddPhoneNumberViewController: UIViewController, ViewType {
    // MARK: - Private properties
    @IBOutlet private weak var addPhoneNumberButton: UIButton!
    @IBOutlet private weak var notNowButton: UIButton!
    @IBOutlet private weak var dontShowAgainButton: UIButton!
    @IBOutlet private weak var addPhoneNumberTitle: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    // MARK: - Internal properties
    var viewModel: AddPhoneNumberViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        viewModel.dispatch(.onViewReady)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if navigationController != nil {
                    AppearanceManager.forceNavigationBarUpdate(navigationController!.navigationBar, traitCollection: traitCollection)
                }
                updateAppearance()
            }
        }
    }
    
    // MARK: - Configure views
    private func configureViews() {
        addPhoneNumberButton.setTitle(NSLocalizedString("Add Phone Number", comment: ""), for: .normal)
        notNowButton.setTitle(NSLocalizedString("notNow", comment: ""), for: .normal)
        dontShowAgainButton.setTitle(NSLocalizedString("dontShowAgain", comment: ""), for: .normal)
        addPhoneNumberTitle.text = NSLocalizedString("Add Phone Number", comment: "")
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        
        addPhoneNumberButton.mnz_setupPrimary(traitCollection)
        notNowButton.mnz_setupCancel(traitCollection)
        dontShowAgainButton.mnz_setupCancel(traitCollection)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: AddPhoneNumberViewModel.Command) {
        switch command {
        case .configView(let hideDontShowAgain):
            dontShowAgainButton.isHidden = hideDontShowAgain
        case .showAchievementStorage(let storage):
            descriptionLabel.text = storage
        case .loadAchievementError(let message):
            descriptionLabel.text = message
        }
    }
    
    // MARK: - UI Actions
    @IBAction func didTapAddPhoneNumberButton() {
        viewModel.dispatch(.addPhoneNumber)
    }

    @IBAction func didTapNotNowButton() {
        viewModel.dispatch(.notNow)
    }
    
    @IBAction func didTapDontShowAgainButton() {
        viewModel.dispatch(.notShowAddPhoneNumberAgain)
    }
}
