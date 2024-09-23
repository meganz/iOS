import MEGADomain
import MEGAL10n
import MEGAPresentation

final class TextEditorViewController: UIViewController {
    private var viewModel: TextEditorViewModel
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()

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
    }
    
    private func setupTextView() {
        view.backgroundColor = UIColor.mnz_backgroundElevated()
        textView.backgroundColor = UIColor.mnz_backgroundElevated()
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        registerForNotifications()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            viewModel.dispatch(.setUpView)
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
        navigationItem.title = textEditorModel.textFile.fileName
        
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
            configToolbar(accessLevel: isBackupNode ? .read : textEditorModel.accessLevel ?? .unknown)
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            toolbarItems = nil
            navigationController?.setToolbarHidden(true, animated: true)
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
                image: navbarItemsModel.rightItem?.image ?? UIImage.moreNavigationBar,
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
        let duplicateNameAC = UIAlertController(
            title: textEditorDuplicateNameAlertModel.alertTitle,
            message: textEditorDuplicateNameAlertModel.alertMessage,
            preferredStyle: .alert
        )
        duplicateNameAC.addAction(
            UIAlertAction(
                title: textEditorDuplicateNameAlertModel.renameButtonTitle,
                style: .default,
                handler: { _ in
                    self.viewModel.dispatch(.renameFile)
                }
            )
        )
        duplicateNameAC.addAction(
            UIAlertAction(
                title: textEditorDuplicateNameAlertModel.replaceButtonTitle,
                style: .default,
                handler: { _ in
                    self.viewModel.dispatch(.uploadFile)
                    self.viewModel.dispatch(.dismissTextEditorVC)
                }
            )
        )
        duplicateNameAC.addAction(
            UIAlertAction(
                title: textEditorDuplicateNameAlertModel.cancelButtonTitle,
                style: .cancel,
                handler: nil
            )
        )
        UIApplication.mnz_presentingViewController().present(duplicateNameAC, animated: true, completion: nil)
    }
    
    private func configRenameAlert(_ textEditorRenameAlertModel: TextEditorRenameAlertModel) {
        let renameAC = UIAlertController(
            title: textEditorRenameAlertModel.alertTitle,
            message: textEditorRenameAlertModel.alertMessage,
            preferredStyle: .alert
        )
        renameAC.addTextField {(textField) in
            textField.text = textEditorRenameAlertModel.textFileName
            textField.placeholder = textEditorRenameAlertModel.textFileName
            textField.addTarget(self, action: #selector(self.renameAlertTextFieldBeginEdit), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(self.renameAlertTextFieldDidChange), for: .editingChanged)
        }
        renameAC.addAction(
            UIAlertAction(
                title: Strings.Localizable.cancel,
                style: .cancel,
                handler: nil
            )
        )
        let renameAction = UIAlertAction(
            title: Strings.Localizable.rename,
            style: .default,
            handler: { _ in
                guard let newInputName = renameAC.textFields?.first?.text else { return }
                if MEGAReachabilityManager.isReachableHUDIfNot() {
                    self.viewModel.dispatch(.renameFileTo(newInputName: newInputName))
                    self.navigationItem.title = newInputName
                }
            })
        renameAction.isEnabled = false
        renameAC.addAction(renameAction)
        UIApplication.mnz_presentingViewController().present(renameAC, animated: true, completion: nil)
    }
    
    private func startLoading() {
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
    
    private func configToolbar(accessLevel: NodeAccessTypeEntity) {
        let flexibleItem =
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            )
        let downloadBarButtonItem =
            UIBarButtonItem(
                image: UIImage.offline,
                style: .plain,
                target: self,
                action: #selector(downloadTapped)
            )
        var toolbarItems = [downloadBarButtonItem, flexibleItem]
        
        if accessLevel != .read {
            let editBarButtonItem =
                UIBarButtonItem(
                    image: UIImage.edittext,
                    style: .plain,
                    target: self,
                    action: #selector(editTapped)
                )
            toolbarItems.append(editBarButtonItem)
            toolbarItems.append(flexibleItem)
        }
        
        if accessLevel == .owner {
            let exportFileBarButtonItem =
                UIBarButtonItem(
                    image: UIImage.export,
                    style: .plain,
                    target: self,
                    action: #selector(exportFileTapped(button:))
                )
            toolbarItems.append(exportFileBarButtonItem)
        } else {
            let importBarButtonItem =
                UIBarButtonItem(
                    image: UIImage.import,
                    style: .plain,
                    target: self,
                    action: #selector(importTapped)
                )
            toolbarItems.append(importBarButtonItem)
        }
        self.toolbarItems = toolbarItems
    }
    
    @objc private func downloadTapped() {
        viewModel.dispatch(.downloadToOffline)
    }
    
    @objc private func editTapped() {
        viewModel.dispatch(.editFile)
    }
    
    @objc private func exportFileTapped(button: UIBarButtonItem) {
        viewModel.dispatch(.exportFile(sender: button))
    }
    
    @objc private func importTapped() {
        viewModel.dispatch(.importNode)
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
    
    @objc private func renameAlertTextFieldBeginEdit(textField: UITextField) {
        guard let name = textField.text else { return }
        let nsName = name as NSString
        let beginning = textField.beginningOfDocument
        var end: UITextPosition
        if (nsName.pathExtension == "") && (name == nsName.deletingPathExtension) {
            end = textField.endOfDocument
        } else {
            let fileNameRange = nsName.range(of: ".", options: .backwards)
            end = textField.position(from: beginning, offset: fileNameRange.location) ?? textField.endOfDocument
        }
        let textRange = textField.textRange(from: beginning, to: end)
        textField.selectedTextRange = textRange
    }
    
    @objc private func renameAlertTextFieldDidChange(textField: UITextField) {
        if let newFileAC = UIApplication.mnz_visibleViewController() as? UIAlertController {
            let rightButtonAction = newFileAC.actions.last
            let containsInvalidChars = textField.text?.mnz_containsInvalidChars() ?? false
            textField.textColor = containsInvalidChars ? UIColor.systemRed : UIColor.label
            let empty = textField.text?.mnz_isEmpty() ?? true
            let noChange = textField.text == textField.placeholder
            rightButtonAction?.isEnabled = (!empty && !containsInvalidChars && !noChange)
        }
    }
    
    func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(notification:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
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
