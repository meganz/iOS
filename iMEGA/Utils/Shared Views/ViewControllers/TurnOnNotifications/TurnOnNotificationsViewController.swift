import MEGADesignToken
import MEGAPresentation
import MEGAUIKit
import UIKit

final class TurnOnNotificationsViewController: UIViewController, ViewType {
    
    private var viewModel: TurnOnNotificationsViewModel!
    
    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = UIColor.label
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = UIColor.label
        return label
    }()
    
    private lazy var openSettingsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var openSettingsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.label
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    private lazy var tapNotificationsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var tapNotificationsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.label
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()

    private lazy var tapMegaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var tapMegaLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.label
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    private lazy var turnOnAllowNotificationsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var turnOnAllowNotificationsLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = UIColor.label
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
        addHeaderImageView()
        
        addContentStack(
            withStepsStack:
                createStepsStack(
                    withStepOneStack: createStepStack(with: [openSettingsImageView, openSettingsLabel]),
                    stepTwoStack: createStepStack(with: [tapNotificationsImageView, tapNotificationsLabel]),
                    stepThreeStack: createStepStack(with: [tapMegaImageView, tapMegaLabel]),
                    stepFourStack: createStepStack(with: [turnOnAllowNotificationsImageView, turnOnAllowNotificationsLabel])
                )
        )
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
            headerImageView.image = turnOnNotificationsModel.headerImage
            titleLabel.text = turnOnNotificationsModel.title
            descriptionLabel.text = turnOnNotificationsModel.description
            
            openSettingsImageView.image = turnOnNotificationsModel.stepOneImage

            let stepOneAttributed = turnOnNotificationsModel.stepOne.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            openSettingsLabel.attributedText = stepOneAttributed
            
            tapNotificationsImageView.image = turnOnNotificationsModel.stepTwoImage
            let stepTwoAttributed = turnOnNotificationsModel.stepTwo.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            tapNotificationsLabel.attributedText = stepTwoAttributed
            
            tapMegaImageView.image = turnOnNotificationsModel.stepThreeImage
            let stepThreeAttributed = turnOnNotificationsModel.stepThree.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            tapMegaLabel.attributedText = stepThreeAttributed

            turnOnAllowNotificationsImageView.image = turnOnNotificationsModel.stepFourImage

            let stepFourAttributed = turnOnNotificationsModel.stepFour.replace(tag: "b",
                                                                             withFont: .preferredFont(forTextStyle: .headline),
                                                                             originalFont: .preferredFont(forTextStyle: .body))
            turnOnAllowNotificationsLabel.attributedText = stepFourAttributed
            
            openSettingsButton.setTitle(turnOnNotificationsModel.openSettingsTitle, for: .normal)
            dismissButton.setTitle(turnOnNotificationsModel.dismissTitle, for: .normal)
        }
    }
    
    // MARK: - Private methods
    
    private func addHeaderImageView() {
        view.addSubview(headerImageView)
        let topAnchorConstant = view.frame.size.height * 0.05
        [headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topAnchorConstant),
         headerImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)].activate()
    }

    private func createStepStack(with views: [UIView]) -> UIStackView {
        let stepStack = UIStackView(arrangedSubviews: views)
        stepStack.axis = .horizontal
        stepStack.alignment = .center
        stepStack.distribution = .fillProportionally
        stepStack.translatesAutoresizingMaskIntoConstraints = false
        stepStack.spacing = 16
        return stepStack
    }
    
    private func createStepsStack(withStepOneStack stepOneStack: UIStackView, stepTwoStack: UIStackView, stepThreeStack: UIStackView, stepFourStack: UIStackView) -> UIStackView {
        let stepsStack = UIStackView(arrangedSubviews: [stepOneStack, stepTwoStack, stepThreeStack, stepFourStack])
        stepsStack.axis = .vertical
        stepsStack.translatesAutoresizingMaskIntoConstraints = false
        stepsStack.spacing = 16
        stepsStack.layoutMargins = UIEdgeInsets(top: 4, left: 20, bottom: 0, right: 20)
        stepsStack.isLayoutMarginsRelativeArrangement = true
        return stepsStack
    }
    
    private func addContentStack(withStepsStack stepsStack: UIStackView) {
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
}

extension TurnOnNotificationsViewController: TraitEnvironmentAware {
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        view.backgroundColor = TokenColors.Background.page
        openSettingsButton.mnz_setupPrimary()
        dismissButton.mnz_setupCancel()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
}
