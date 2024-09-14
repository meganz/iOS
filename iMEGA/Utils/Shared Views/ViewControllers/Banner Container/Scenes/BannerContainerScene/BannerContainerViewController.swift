import MEGADesignToken

final class BannerContainerViewController: UIViewController {
    @IBOutlet weak var bannerContainerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var bannerMessageLabel: MEGALabel!
    @IBOutlet weak var bannerActionButton: UIButton!
    
    var viewModel: BannerContainerViewModel!
    var contentVC: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(contentVC, container: contentContainerView)
       
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewDidLoad(traitCollection))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.dispatch(.onViewWillAppear)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            viewModel.dispatch(.onTraitCollectionDidChange(traitCollection))
        }
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateLabelsFontSizes()
        }
    }
    
    private func configureBannerView(message: String, backgroundColor: UIColor, textColor: UIColor, actionIcon: UIImage?) {
        bannerContainerView.backgroundColor = backgroundColor
        bannerMessageLabel.text = message
        bannerMessageLabel.textColor = textColor
        if let actionIcon = actionIcon {
            bannerActionButton.tintColor = TokenColors.Icon.secondary
            bannerActionButton.setImage(actionIcon, for: .normal)
        }
    }
    
    private func updateLabelsFontSizes() {
        bannerMessageLabel.font = UIFont.preferredFont(style: .caption2, weight: .semibold)
    }
    
    private func isBanner(enabled: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.bannerContainerView.isHidden = !enabled
            }
        } else {
            bannerContainerView.isHidden = !enabled
        }
    }
    
    @IBAction func bannerButtonAction(_ sender: Any) {
        viewModel.dispatch(.onClose)
    }
    
    func executeCommand(_ command: BannerContainerViewModel.Command) {
        switch command {
        case .configureView(let message, let backgroundColor, let textColor, let actionIcon):
            configureBannerView(message: message, backgroundColor: backgroundColor, textColor: textColor, actionIcon: actionIcon)
        case .hideBanner(let animated):
            isBanner(enabled: false, animated: animated)
        case .showBanner(let animated):
            isBanner(enabled: true, animated: animated)
        }
    }
}
