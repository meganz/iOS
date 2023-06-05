import UIKit
import MEGAUIKit

/// A protocol defines `SearchBarView`'s search session.
protocol MEGASearchBarViewDelegate: AnyObject {

    /// Tells the delegte that the search bar view started a new search session. Normally, the new session begins when
    /// user tapping into the search field.
    /// - Parameter searchController: The `SearchBarView` itself.
    func didStartSearchSessionOnSearchController(_ searchController: MEGASearchBarView)

    /// Tells the delegate that the search bar view resumed from a existing session. This normally happens when user
    /// tapping into the search field with text in.
    /// - Parameter searchController: The `SearchBarView` itself.
    func didResumeSearchSessionOnSearchController(_ searchController: MEGASearchBarView)

    /// Tells the delegate that the search bar search session is finished. This normally happens when user
    /// tapping `Cancel` button and leave editting the search field..
    /// - Parameter searchController: The `SearchBarView` itself.
    func didFinishSearchSessionOnSearchController(_ searchController: MEGASearchBarView)
}

protocol MEGASearchBarViewEdittingDelegate: AnyObject {

    /// Tells the `delegate` that user highlights the search field in the `SearchBarView`.
    /// - Parameter searchController: The `SearchBarView` itself.
    func didHighlightSearchController(_ searchController: MEGASearchBarView)

    /// Tell teh `delegate` that new text `inputText` is updated in the `SearchField` on `SearchBarView`.
    /// - Parameters:
    ///   - inputText: The newly updated text that in the text field.
    ///   - searchController: The `SearchBarView` itself.
    func didInputText(_ inputText: String, from searchController: MEGASearchBarView)

    /// Tells the `delegate` the **clear** button is tapped and all text in the `TextField` is removed.
    /// - Parameter searchController: The `SearchBarView` itself.
    func didClearText(for searchController: MEGASearchBarView)
}

final class MEGASearchBarView: UIView, NibOwnerLoadable {

    @IBOutlet private weak var searchField: UITextField!

    @IBOutlet private weak var cancelButton: UIButton!

    private weak var contentView: UIView!

    private weak var searchIconImageView: UIImageView!

    weak var delegate: MEGASearchBarViewDelegate?

    weak var edittingDelegate: MEGASearchBarViewEdittingDelegate?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialise()
        setupView(with: traitCollection)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialise()
        setupView(with: traitCollection)
    }

    // MARK: - Privates

    private func initialise() {
        guard let contentView = loadedViewFromNibContent() else { return }
        self.contentView = contentView

        func initialise(contentView: UIView) {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            contentView.autoPinEdgesToSuperviewEdges()
        }

        func initialise(cancelButton: UIButton) {
            cancelButton.isHidden = true
            cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        }

        func initialise(searchField: UITextField) {
            searchField.setLeftImage(Asset.Images.Home.searchBarIcon.image)
            searchField.placeholder = HomeLocalisation.searchYourFiles.rawValue
            searchField.delegate = self
        }

        initialise(contentView: contentView)
        initialise(cancelButton: cancelButton)
        initialise(searchField: searchField)
    }

    @objc private func didTapCancelButton() {
        searchField.text = nil
        searchField.resignFirstResponder()
        cancelButton.isHidden = true
        delegate?.didFinishSearchSessionOnSearchController(self)
    }

    private func setupView(with trait: UITraitCollection) {
        let backgroundStyler = trait.theme.customViewStyleFactory.styler(of: .searchController)
        backgroundStyler(self)
        backgroundStyler(contentView)

        let searchFieldStyler = trait.theme.textFieldStyleFactory.styler(of: .searchBar)
        searchFieldStyler(searchField)

        let cancelButtonStyler = trait.theme.buttonStyle.styler(of: .searchControllerCancel)
        cancelButtonStyler(cancelButton)
    }

    private func setupBackgroundColor(with trait: UITraitCollection) {
        switch trait.theme {
        case .dark:
            backgroundColor = .black
            subviews.first?.backgroundColor = .black
        default:
            backgroundColor = .mnz_grayF7F7F7()
            subviews.first?.backgroundColor = .mnz_grayF7F7F7()
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return searchField.becomeFirstResponder()
    }
}

// MARK: - TraitEnviromentAware

extension MEGASearchBarView: TraitEnviromentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupView(with: currentTrait)
    }

    func contentSizeCategoryDidChange(to contentSizeCategory: UIContentSizeCategory) {}
}

// MARK: - UITextFieldDelegate

extension MEGASearchBarView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let textFieldText = textField.text, !textFieldText.isEmpty else {
            cancelButton.isHidden = false
            delegate?.didStartSearchSessionOnSearchController(self)
            edittingDelegate?.didHighlightSearchController(self)
            return
        }
        delegate?.didResumeSearchSessionOnSearchController(self)
        edittingDelegate?.didInputText(textFieldText, from: self)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        let shouldClearText = (textField.text?.isEmpty == false)
        if shouldClearText {
            edittingDelegate?.didClearText(for: self)
        }
        return shouldClearText
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return true
        }
        edittingDelegate?.didInputText(newText, from: self)
        return true
    }
}

// MARK: - HomeSearchControllerDelegate

extension MEGASearchBarView: HomeSearchControllerDelegate {
    func didSelect(searchText: String) {
        searchField.text = searchText
    }
}
