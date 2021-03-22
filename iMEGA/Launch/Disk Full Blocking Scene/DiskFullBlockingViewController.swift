import UIKit

final class DiskFullBlockingViewController: UIViewController, ViewType {
    
    private var viewModel: DiskFullBlockingViewModel
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = UIColor.mnz_label()
        label.setContentCompressionResistancePriority(.defaultHigh + 2, for: .vertical)
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.mnz_label()
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
        let imageView = UIImageView(image: UIImage(named: "blockingDiskFull"))
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
        
        if #available(iOS 11.0, *) {
            [contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -35)].activate()
        } else {
            [contentStack.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor, constant: -35)].activate()
        }
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
        case let .configView(title, description, manageTitle):
            titleLabel.text = title
            descriptionLabel.attributedText = description
            manageButton.setTitle(manageTitle, for: .normal)
        }
    }
}

extension DiskFullBlockingViewController: TraitEnviromentAware {
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        view.backgroundColor = UIColor.mnz_backgroundElevated(currentTrait)
        manageButton.mnz_setupPrimary(currentTrait)
    }
}
