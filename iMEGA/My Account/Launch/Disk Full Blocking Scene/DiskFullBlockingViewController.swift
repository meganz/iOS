import MEGAAppPresentation
import MEGADesignToken
import MEGAUIKit
import UIKit

final class DiskFullBlockingViewController: UIViewController, ViewType {
    
    private var viewModel: DiskFullBlockingViewModel
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.setContentCompressionResistancePriority(.defaultHigh + 2, for: .vertical)
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.label
        label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)
        return label
    }()
    
    private lazy var manageButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setContentCompressionResistancePriority(.defaultHigh + 3, for: .vertical)
        button.addTarget(self, action: #selector(didTapManageButton), for: .touchUpInside)
        [button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)].activate()
        return button
    }()
    
    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var headerImageHeightConstraint: NSLayoutConstraint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        colorAppearanceDidChange(to: traitCollection, from: nil)
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewLoaded)
    }
    
    init(viewModel: DiskFullBlockingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: setup view
    private func setupViews() {
        view.addSubview(headerImageView)
        [headerImageView.topAnchor.constraint(equalTo: view.topAnchor),
         headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         headerImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.33)].activate()
        
        let contentStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, UIView.makeFlexiView(for: .vertical), manageButton])
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.spacing = 16
        view.addSubview(contentStack)
        [contentStack.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 30),
         contentStack.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
         contentStack.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor)].activate()
        
        [contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -35)].activate()
    }
    
    // MARK: view configuration
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    // MARK: UI actions
    @objc private func didTapManageButton() {
        viewModel.dispatch(.manage)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: DiskFullBlockingViewModel.Command) {
        switch command {
        case let .configView(blockingModel):
            titleLabel.text = blockingModel.title
            manageButton.setTitle(blockingModel.manageDiskSpaceTitle, for: .normal)
            headerImageView.image = blockingModel.headerImage
            descriptionLabel.attributedText = buildDescriptionText(by: blockingModel)
        }
    }
    
    private func buildDescriptionText(by blockingModel: DiskFullBlockingModel) -> NSAttributedString {
        let attributedString =
            NSMutableAttributedString(string: blockingModel.description,
                                      attributes:
                                        [.font: UIFont.preferredFont(forTextStyle: .subheadline)])
        let range = NSString(string: blockingModel.description).range(of: blockingModel.highlightedText)
        attributedString.addAttributes([.font: UIFont.preferredFont(forTextStyle: .subheadline).bold()],
                                       range: range)
        return attributedString.copy() as! NSAttributedString
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) { return }
    
    override func show(_ vc: UIViewController, sender: Any?) { return }
    
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) { return }
}

extension DiskFullBlockingViewController: TraitEnvironmentAware {
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        view.backgroundColor = TokenColors.Background.page
        manageButton.mnz_setupPrimary()
    }
}
