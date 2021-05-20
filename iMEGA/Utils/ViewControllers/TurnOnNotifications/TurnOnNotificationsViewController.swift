
import UIKit

final class TurnOnNotificationsViewController: UIViewController, ViewType {
    
    private var viewModel: TurnOnNotificationsViewModel!
    
    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = UIColor.mnz_label()
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = UIColor.mnz_label()
        return label
    }()
    
    private lazy var openSettingsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        return imageView
    }()
    
    private lazy var openSettingsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.mnz_label()
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    private lazy var tapNotificationsImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var tapNotificationsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.mnz_label()
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    private lazy var turnOnAllowNotificationsImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var turnOnAllowNotificationsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.mnz_label()
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    private lazy var openSettingsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(didTapOpenSettingsButton), for: .touchUpInside)
        [button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)].activate()
        return button
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
        [button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)].activate()
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        colorAppearanceDidChange(to: traitCollection, from: nil)
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewLoaded)
    }
    
    init(viewModel: TurnOnNotificationsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: view configuration
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    // MARK: - Private
    
    private func setupViews() {
        view.addSubview(headerImageView)
        
        [headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 83),
         headerImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
         headerImageView.heightAnchor.constraint(equalToConstant: 80),
         headerImageView.widthAnchor.constraint(equalToConstant: 85)].activate()
        
        let stepOneStack = UIStackView(arrangedSubviews: [openSettingsImageView, openSettingsLabel])
        stepOneStack.axis = .horizontal
        stepOneStack.alignment = .center
        stepOneStack.translatesAutoresizingMaskIntoConstraints = false
        stepOneStack.spacing = 16
        
        [openSettingsImageView.heightAnchor.constraint(equalToConstant: 30),
         openSettingsImageView.widthAnchor.constraint(equalToConstant: 30)].activate()
        
        let stepTwoStack = UIStackView(arrangedSubviews: [tapNotificationsImageView, tapNotificationsLabel])
        stepTwoStack.axis = .horizontal
        stepTwoStack.alignment = .center
        stepTwoStack.translatesAutoresizingMaskIntoConstraints = false
        stepTwoStack.spacing = 16
        
        [tapNotificationsImageView.heightAnchor.constraint(equalToConstant: 30),
         tapNotificationsImageView.widthAnchor.constraint(equalToConstant: 30)].activate()
        
        let stepThreeStack = UIStackView(arrangedSubviews: [turnOnAllowNotificationsImageView, turnOnAllowNotificationsLabel])
        stepThreeStack.axis = .horizontal
        stepThreeStack.alignment = .center
        stepThreeStack.translatesAutoresizingMaskIntoConstraints = false
        stepThreeStack.spacing = 16
        
        [turnOnAllowNotificationsImageView.heightAnchor.constraint(equalToConstant: 30),
         turnOnAllowNotificationsImageView.widthAnchor.constraint(equalToConstant: 30)].activate()
        
        let stepsStack = UIStackView(arrangedSubviews: [stepOneStack, stepTwoStack, stepThreeStack])
        stepsStack.axis = .vertical
        stepsStack.translatesAutoresizingMaskIntoConstraints = false
        stepsStack.spacing = 16
        stepsStack.layoutMargins = UIEdgeInsets(top: 4, left: 20, bottom: 0, right: 20)
        stepsStack.isLayoutMarginsRelativeArrangement = true
        
        let contentStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, stepsStack, UIView.makeFlexiView(for: .vertical), openSettingsButton, dismissButton])
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.spacing = 16
        view.addSubview(contentStack)
        [contentStack.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 30),
         contentStack.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
         contentStack.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
         contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -35)].activate()
    }
    
    // MARK: - UI actions
    @objc private func didTapOpenSettingsButton() {
        viewModel.dispatch(.openSettings)
    }
    
    @objc private func didTapDismiss() {
        viewModel.dispatch(.dismiss)
    }
    
    // MARK: - Commands
    func executeCommand(_ command: TurnOnNotificationsViewModel.Command) {
        switch command {
        case let .configView(turnOnNotificationsModel):
            headerImageView.image = UIImage(named: turnOnNotificationsModel.headerImageName)
            titleLabel.text = turnOnNotificationsModel.title
            descriptionLabel.text = turnOnNotificationsModel.description
            
            openSettingsImageView.image = UIImage(named: turnOnNotificationsModel.stepOneImageName)

            let stepOneAttributed = turnOnNotificationsModel.stepOne.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            openSettingsLabel.attributedText = stepOneAttributed
            
            tapNotificationsImageView.image = UIImage(named: turnOnNotificationsModel.stepTwoImageName)
            let stepTwoAttributed = turnOnNotificationsModel.stepTwo.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            tapNotificationsLabel.attributedText = stepTwoAttributed
            
            turnOnAllowNotificationsImageView.image = UIImage(named: turnOnNotificationsModel.stepThreeImageName)
            
            let stepThreeAttributed = turnOnNotificationsModel.stepThree.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            turnOnAllowNotificationsLabel.attributedText = stepThreeAttributed
            
            openSettingsButton.setTitle(turnOnNotificationsModel.openSettingsTitle, for: .normal)
            dismissButton.setTitle(turnOnNotificationsModel.dismissTitle, for: .normal)
        }
    }
}

extension TurnOnNotificationsViewController: TraitEnviromentAware {
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        view.backgroundColor = UIColor.mnz_backgroundElevated(currentTrait)
        openSettingsButton.mnz_setupPrimary(currentTrait)
        dismissButton.mnz_setupCancel(currentTrait)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
}
