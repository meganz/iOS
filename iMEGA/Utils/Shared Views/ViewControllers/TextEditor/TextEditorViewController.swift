import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

final class TextEditorViewController: UIViewController {
    private var viewModel: TextEditorViewModel
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()
    
    private var markdownSupportTextViewController: UIViewController?
    /// The character offset (if any) the text view need to jump to at first render. Nil means no offset to jump to and 0 means
    /// textView starts from top
    private var resumeLastReadOffset: Int?

    private weak var activityIndicator: UIActivityIndicatorView?
    private weak var progressView: UIProgressView?
    private weak var imageView: UIImageView?
    
    init(viewModel: TextEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextView()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async {
                self?.executeCommand(command)
            }
        }
        
        viewModel.dispatch(.setUpView)
        registerForTraitChangesAffectingEditor()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // There's a case where user closes the screen while the textView is still scrolling,
        // In which case we also need to save the reading position 
        reportAndSaveReadingPosition()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !textView.isHidden, let offset = resumeLastReadOffset else { return }
        resumeLastReadOffset = nil
        restoreLegacyTextViewPosition(offset)
    }

    /// A rotation reflows the text, so an offset in points no longer points at the same line.
    /// The character anchor is captured before the transition and re-applied after it.
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard !textView.isHidden else { return }

        let anchor = currentLegacyTextViewAnchor
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.restoreLegacyTextViewPosition(anchor)
        }
    }

    private func setupTextView() {
        view.backgroundColor = TokenColors.Background.page
        textView.backgroundColor = TokenColors.Background.page
        textView.delegate = self
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        registerForNotifications()
    }
    
    /// The editor rebuilds its view for a new content size category and restyles the iOS 26
    /// navigation bar for a new colour appearance, so both trait groups have to be observed.
    private func registerForTraitChangesAffectingEditor() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (viewController: TextEditorViewController, _: UITraitCollection) in
            viewController.viewModel.dispatch(.setUpView)
        }

        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (viewController: TextEditorViewController, _: UITraitCollection) in
            if #available(iOS 26.0, *),
               let navigationBar = viewController.navigationController?.navigationBar {
                AppearanceManager.setupLiquidGlassNavigationBar(navigationBar)
            }
        }
    }
}

// MARK: - U-R-MVVM ViewController ViewType
extension TextEditorViewController: ViewType {
    func executeCommand(_ command: TextEditorViewModel.Command) {
        switch command {
        case .configView(let textEditorModel, let shallUpdateContent, let isInRubbishBin, let isBackupNode):
            configView(textEditorModel, shallUpdateContent: shallUpdateContent, isInRubbishBin: isInRubbishBin, isBackupNode: isBackupNode)
        case .setupNavbarItems(let navbarItemsModel):
            setupNavbarItems(navbarItemsModel)
        case .setupLoadViews:
            setUpLoadViews()
        case .updateProgressView(let percentage):
            setProgressView(percentage: percentage)
        case .editFile:
            editTapped()
        case .showDuplicateNameAlert(let textEditorDuplicateNameAlertModel):
            configDuplicateNameAlert(textEditorDuplicateNameAlertModel)
        case .showRenameAlert(let textEditorRenameAlertModel):
            configRenameAlert(textEditorRenameAlertModel)
        case .startLoading:
            startLoading()
        case .stopLoading:
            SVProgressHUD.dismiss()
        case .showError(let error):
            SVProgressHUD.showError(withStatus: error)
        case .showDiscardChangeAlert:
            showDiscardChangeAlert()
        }
    }
    
    @objc func editAfterOpen() {
        viewModel.dispatch(.editAfterOpen)
    }
    
    private func configView(_ textEditorModel: TextEditorModel, shallUpdateContent: Bool, isInRubbishBin: Bool, isBackupNode: Bool) {
        TextEditorBarItems.applyTitle(textEditorModel.textFile.fileName, to: navigationItem, shouldEnableGlassEffect: false)

        let contentOffset = textView.contentOffset
        if shallUpdateContent {
            textView.text = textEditorModel.textFile.content
        }
        textView.isEditable = textEditorModel.isEditable
        let position = textView.closestPosition(to: contentOffset) ?? textView.beginningOfDocument
        if textEditorModel.isEditable {
            textView.becomeFirstResponder()
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
        if shallUpdateContent {
            let location = textView.offset(from: textView.beginningOfDocument, to: position)
            textView.scrollRangeToVisible(NSRange(location: location, length: 0))
        }
        
        if textEditorModel.textEditorMode == .load {
            imageView?.image = NodeAssetsManager.shared.image(for: NSString(string: textEditorModel.textFile.fileName).pathExtension)
        } else {
            imageView?.isHidden = true
            activityIndicator?.isHidden = true
            progressView?.isHidden = true
        }
        
        if textEditorModel.textEditorMode == .view && !isInRubbishBin {
            toolbarItems = TextEditorBarItems.bottomBarItems(
                accessLevel: isBackupNode ? .read : textEditorModel.accessLevel ?? .unknown,
                usesLinkRevampIcons: textEditorModel.usesLinkRevampIcons,
                target: self
            )
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            toolbarItems = nil
            navigationController?.setToolbarHidden(true, animated: true)
        }
        
        configureMarkdownSupportText(textEditorModel)

        if #available(iOS 26.0, *),
           let navigationBar = navigationController?.navigationBar {
            AppearanceManager.setupLiquidGlassNavigationBar(navigationBar)
        }
    }
    
    private func setupNavbarItems(_ navbarItemsModel: TextEditorNavbarItemsModel) {
        switch navbarItemsModel.textEditorMode {
        case .load:
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: navbarItemsModel.leftItem.title,
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
            navigationItem.rightBarButtonItem = nil
        case .view:
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: navbarItemsModel.leftItem.title,
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: navbarItemsModel.rightItem?.image ?? MEGAAssets.UIImage.moreNavigationBar,
                style: .plain,
                target: self,
                action: #selector(moreTapped(button:))
            )
        case .edit,
             .create:
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: navbarItemsModel.leftItem.title,
                style: .plain,
                target: self,
                action: #selector(cancelTapped)
            )
            let saveButton = UIBarButtonItem(
                title: navbarItemsModel.rightItem?.title,
                style: .plain,
                target: self,
                action: #selector(saveTapped)
            )
            let attribute: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(style: .callout, weight: .bold)]
            saveButton.setTitleTextAttributes(attribute, for: .normal)
            
            navigationItem.rightBarButtonItem = saveButton
        }

        TransferIndicatorBarItemConfigurator.injectIfNeeded(into: self)
    }

    private func setUpLoadViews() {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        self.activityIndicator = activityIndicator
        
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalToConstant: 150),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        self.progressView = progressView
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: activityIndicator.topAnchor, constant: -20)
        ])
        
        self.imageView = imageView
    }
    
    private func setProgressView(percentage: Float) {
        activityIndicator?.stopAnimating()
        progressView?.isHidden = false
        progressView?.setProgress(percentage, animated: true)
    }
    
    private func configDuplicateNameAlert(_ textEditorDuplicateNameAlertModel: TextEditorDuplicateNameAlertModel) {
        let duplicateNameAC = TextEditorFileNameAlerts.makeDuplicateNameAlert(
            textEditorDuplicateNameAlertModel,
            onRename: { [weak self] in
                self?.viewModel.dispatch(.renameFile)
            },
            onReplace: { [weak self] in
                self?.viewModel.dispatch(.uploadFile)
            }
        )
        UIApplication.mnz_presentingViewController().present(duplicateNameAC, animated: true, completion: nil)
    }
    
    private func configRenameAlert(_ textEditorRenameAlertModel: TextEditorRenameAlertModel) {
        let renameAC = TextEditorFileNameAlerts.makeRenameAlert(textEditorRenameAlertModel) { [weak self] newInputName in
            guard let self, MEGAReachabilityManager.isReachableHUDIfNot() else { return }
            viewModel.dispatch(.renameFileTo(newInputName: newInputName))
            TextEditorBarItems.applyTitle(newInputName, to: navigationItem, shouldEnableGlassEffect: true)
        }
        UIApplication.mnz_presentingViewController().present(renameAC, animated: true, completion: nil)
    }
    
    private func startLoading() {
        // The HUD mask blocks taps, but the keyboard window still sends key presses to the text view.
        view.endEditing(true)
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
    
    private func showDiscardChangeAlert() {
        guard let barButton = navigationItem.leftBarButtonItem else { return }
        let discardChangesAC = UIAlertController().discardChanges(
            fromBarButton: barButton,
            withConfirmAction: {
                self.viewModel.dispatch(.cancel)
            }
        )
        present(discardChangesAC, animated: true, completion: nil)
    }
    
    @objc private func cancelTapped() {
        viewModel.dispatch(.cancelText(content: textView.text))
    }
    
    @objc private func saveTapped() {
        viewModel.dispatch(.saveText(content: textView.text))
    }
    
    @objc private func closeTapped() {
        viewModel.dispatch(.dismissTextEditorVC)
    }
    
    @objc private func moreTapped(button: UIButton) {
        viewModel.dispatch(.showActions(sender: button))
    }
    
    func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(notification:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc func didEnterBackground() {
        reportAndSaveReadingPosition()
    }
    
    @objc func keyboardDidChangeFrame(notification: NSNotification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        textView.scrollIndicatorInsets = textView.contentInset
    }
    
    @objc func keyboardDidHide(notification: NSNotification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = textView.contentInset
    }
}

// MARK: - TextEditorBarItemTarget
extension TextEditorViewController: TextEditorBarItemTarget {
    func downloadTapped() {
        viewModel.dispatch(.downloadToOffline)
    }

    func editTapped() {
        viewModel.dispatch(.editFile)
    }

    func exportFileTapped(button: UIBarButtonItem) {
        viewModel.dispatch(.exportFile(sender: button))
    }

    func importTapped() {
        viewModel.dispatch(.importNode)
    }
}

// MARK: - Markdown support

extension TextEditorViewController {
    
    private func configureMarkdownSupportText(_ textEditorModel: TextEditorModel) {
        switch textEditorModel.textEditorMode {
        case .view:
            if textEditorModel.textFile.fileName.fileExtensionGroup.isMarkdownText {
                renderTextUsingMarkdownSupportRenderingOnView(textEditorModel)
            } else {
                renderTextUsingLegacyTextView(isEditable: false, resumeReadingOffset: textEditorModel.resumeReadingOffset)
            }
        case .edit:
            renderTextUsingLegacyTextView(isEditable: true, resumeReadingOffset: nil)
        case .create, .load:
            break
        }
    }
    
    private func renderTextUsingMarkdownSupportRenderingOnView(_ textEditorModel: TextEditorModel) {
        let isRebuild = markdownSupportTextViewController != nil
        removeMarkdownSupportTextRenderingFromView()

        let markdownTextView = MarkdownSupportTextView(
            viewModel: MarkdownSupportTextViewModel(string: textEditorModel.textFile.content)
        )
        let controller = UIHostingController(rootView: markdownTextView)
        controller.view.backgroundColor = .clear
        markdownSupportTextViewController = controller
        add(controller, container: view, animate: !isRebuild)

        textView.isHidden = true
    }
    
    private func renderTextUsingLegacyTextView(isEditable: Bool, resumeReadingOffset: Int?) {
        textView.isEditable = isEditable
        textView.isHidden = false
        removeMarkdownSupportTextRenderingFromView()

        guard !isEditable else {
            resumeLastReadOffset = nil
            return
        }

        // The restore needs the final content size. It is only correct once the bottom toolbar and
        // safe area have been applied, which has not happened yet at this point,
        // so we need to wait for the next layout pass in `viewDidLayoutSubiews()`
        resumeLastReadOffset = resumeReadingOffset ?? 0
        view.setNeedsLayout()
    }

    /// The anchor is a character offset, not a point offset, so it survives the reflow caused by a
    /// rotation or a font size change.
    private func restoreLegacyTextViewPosition(_ offset: Int?) {
        UIView.performWithoutAnimation { applyLegacyTextViewPosition(offset) }
        reportLegacyTextViewPosition()
    }

    private func applyLegacyTextViewPosition(_ offset: Int?) {
        textView.layoutIfNeeded()
        let length = legacyTextViewLength
        guard let offset, offset > 0, length > 0 else {
            textView.setContentOffset(.zero, animated: false)
            return
        }

        let characterIndex = min(offset, length - 1)

        // We want to scroll the textView so that characterIndex is visible at the top-left corner
        // of the viewport. A simple way to achieve this is to (1) jump to the bottom of the textVie first
        // and (2) scroll back using `scrollRangeToVisible`
        // Without (1), `scrollRangeToVisible` will scroll from the top and stop when
        // characterIndex is barely visible which put it at the bottom edge of the textView
        // which is not what we want
        textView.setContentOffset(CGPoint(x: 0, y: legacyTextViewMaximumOffset), animated: false)
        textView.scrollRangeToVisible(NSRange(location: characterIndex, length: 0))
    }

    private func reportAndSaveReadingPosition() {
        // We don't support reading position for markdown. So
        // checking `!textView.isHidden` to exclude markdown types.
        guard !textView.isHidden else { return }

        reportLegacyTextViewPosition()
        viewModel.dispatch(.saveReadingPosition)
    }

    /// A file opened and closed without scrolling never reports anything, so the progress has to be
    /// sent once the restore has settled.
    private func reportLegacyTextViewPosition() {
        guard !textView.isEditable else { return }

        viewModel.dispatch(
            .updateReadingPosition(
                anchor: currentLegacyTextViewAnchor,
                progress: currentLegacyTextViewProgress
            )
        )
    }

    private var legacyTextViewMaximumOffset: CGFloat {
        max(textView.contentSize.height - textView.bounds.height, 0)
    }

    private var legacyTextViewLength: Int {
        textView.offset(from: textView.beginningOfDocument, to: textView.endOfDocument)
    }

    /// The offset the character at the top of the visible viewport.
    private var currentLegacyTextViewAnchor: Int? {
        guard let textPosition = textView.closestPosition(to: textView.contentOffset) else { return nil }
        return textView.offset(from: textView.beginningOfDocument, to: textPosition)
    }

    /// How far the content has been seen: In form of the fraction of the laid out height.
    /// - A file that fits on one screen is considered completely seen
    /// - A file scrolled to the bottom is also consider completely seen
    private var currentLegacyTextViewProgress: Double {
        let maximumOffset = legacyTextViewMaximumOffset
        guard maximumOffset > 0 else { return 1 }
        guard textView.contentOffset.y < maximumOffset - 1 else { return 1 }

        return max(textView.contentOffset.y / maximumOffset, 0)
    }

    private func removeMarkdownSupportTextRenderingFromView() {
        remove(childViewController: markdownSupportTextViewController)
        markdownSupportTextViewController = nil
    }
}

// MARK: - UITextViewDelegate

extension TextEditorViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !textView.isEditable,
              scrollView.isDragging || scrollView.isDecelerating else { return }
        viewModel.dispatch(.updateReadingPosition(anchor: nil, progress: currentLegacyTextViewProgress))
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        reportLegacyTextViewPosition()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        reportLegacyTextViewPosition()
    }
}
