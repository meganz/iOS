import MEGADesignToken
import MEGAUIKit
import UIKit

final class SegmentTitleView: UIView {

    struct SegmentTitleViewModel {
        struct Title {
            let text: String
            let index: Int
        }

        let titles: [Title]
    }

    private var buttons: [UIButton] = []

    private var horizontalStackContainer: UIStackView?

    private var model: SegmentTitleViewModel?

    var selectAction: ((SegmentTitleViewModel.Title) -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView(with: traitCollection)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(with: traitCollection)
    }

    // MARK: - Public Interface

    func setSegmentTitleViewModel(model: SegmentTitleViewModel) {
        self.model = model
        setTitles(model.titles)
    }

    func selectTab(_ index: Int) {
        setSelected(at: index, of: buttons)
    }
    
    // MARK: - Private

    private func setTitles(_ titles: [SegmentTitleViewModel.Title]) {
        let titleButtonStyler = traitCollection.theme.buttonStyle.styler(of: .segmentTitleButton)
        let buttons: [UIButton] = titles.enumerated().map { (index: Int, title: SegmentTitleViewModel.Title)  in
            let button = UIButton(type: .custom)
            button.setTitle(title.text, for: .normal)
            button.tag = title.index
            if index == 0 { button.isSelected = true }
            button.addTarget(self, action: #selector(didTap(button:)), for: .touchUpInside)
            titleButtonStyler(button)
            return button
        }

        self.buttons = buttons
        horizontalStackContainer?.removeFromSuperview()
        horizontalStackContainer = createStackView(with: buttons)
    }

    private func setSelected(at index: Int, of buttons: [UIButton]) {
        deselect(buttons: buttons)
        select(index: index, in: buttons)
        
        let titleButtonStyler = traitCollection.theme.buttonStyle.styler(of: .segmentTitleButton)
        buttons.forEach(titleButtonStyler)
    }

    private func deselect(buttons: [UIButton]) {
        buttons.forEach { $0.isSelected = false }
    }

    private func select(index: Int, in buttons: [UIButton]) {
        guard index < buttons.count else { return }
        buttons[index].isSelected = true
    }

    // MARK: - Actions

    @objc private func didTap(button: UIButton) {
        guard let index = buttons.firstIndex(of: button) else { return }
        setSelected(at: index, of: buttons)

        if let titles = model?.titles {
            selectAction?(titles[index])
        }
    }

    // MARK: - View Setup

    private func setupView(with trait: UITraitCollection) {
        updateView(with: trait)
    }

    private func updateView(with trait: UITraitCollection) {
        updateButtons(buttons, withTrait: trait)
        backgroundColor = TokenColors.Background.page
    }

    private func updateButtons(_ buttons: [UIButton], withTrait trait: UITraitCollection) {
        let styleTitleButton = traitCollection.theme.buttonStyle.styler(of: .segmentTitleButton)
        buttons.forEach(styleTitleButton)

        switch trait.theme {
        case .dark: backgroundColor = TokenColors.Text.primary
        case .light: backgroundColor = TokenColors.Text.primary
        }
    }

    private func createStackView(with buttons: [UIView]) -> UIStackView {
        let horizontalStackContainer = (buttons).embedInStackView(
            axis: .horizontal,
            distribution: .fill,
            spacing: Constants.spacingBetweenButtons
        )
        pinStackView(horizontalStackContainer)
        return horizontalStackContainer
    }

    private func pinStackView(_ stackView: UIStackView) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: Constants.stackViewInset),
            stackView.topAnchor.constraint(equalTo: topAnchor)
        ])

        stackView.backgroundColor = TokenColors.Background.page
    }

    private enum Constants {
        static let spacingBetweenButtons: CGFloat = 16
        static let stackViewInset: CGFloat = 16
    }
}
