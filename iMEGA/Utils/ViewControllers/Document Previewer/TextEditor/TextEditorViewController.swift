final class TextEditorViewController: UIViewController {
    private var viewModel: TextEditorViewModel
    private var fileName: String?
    
    private lazy var textView: UITextView = UITextView()
    private lazy var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private lazy var progressView: UIProgressView = UIProgressView()
    private lazy var imageView: UIImageView = UIImageView()
    
    init(viewModel: TextEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async {
                self?.executeCommand(command)
            }
        }
        
        viewModel.dispatch(.setUpView)
    }
    
    private func setupViews() {
        view.addSubview(textView)
        textView.autoPinEdgesToSuperviewSafeArea()
        
        view.addSubview(activityIndicator)
        activityIndicator.autoCenterInSuperview()
        
        view.addSubview(progressView)
        progressView.autoSetDimension(.width, toSize: 150)
        progressView.autoCenterInSuperview()
        
        view.addSubview(imageView)
        imageView.autoSetDimension(.height, toSize: 80)
        imageView.autoSetDimension(.width, toSize: 80)
        imageView.autoAlignAxis(toSuperviewMarginAxis: .vertical)
        imageView.autoPinEdge(.bottom, to: .top, of: activityIndicator, withOffset: -20)
    }
}

//MARK: - U-R-MVVM ViewController ViewType
extension TextEditorViewController: ViewType {
    func executeCommand(_ command: TextEditorViewModel.Command) {
        switch command {
        case .configView(let textEditorModel):
            configView(textEditorModel)
        case .updateProgressView(let percentage):
            setProgressView(percentage)
        case .editFile:
            editFile()
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
        }
    }
    
    private func configView(_ textEditorModel: TextEditorModel) {
        textView.isEditable = (textEditorModel.textEditorMode == .create || textEditorModel.textEditorMode == .edit)
        navigationItem.title = textEditorModel.textFile.fileName
        
        if textEditorModel.textEditorMode == .load {
            imageView.mnz_setImage(forExtension: NSString(string: textEditorModel.textFile.fileName).pathExtension)
        } else {
            imageView.isHidden = true
            activityIndicator.isHidden = true
            progressView.isHidden = true
        }
        
        textView.text = textEditorModel.textFile.content
        
        if textView.isEditable {
            textView.becomeFirstResponder()
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: textEditorModel.leftButtonTitle,
                style: .plain,
                target: self,
                action: #selector(cancelTapped)
            )
            let saveButton = UIBarButtonItem(
                title: textEditorModel.rightButtonTitle,
                style: .plain,
                target: self,
                action: #selector(saveTapped)
            )
            let attribute: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
            saveButton.setTitleTextAttributes(attribute, for: .normal)
            
            navigationItem.rightBarButtonItem = saveButton
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: textEditorModel.leftButtonTitle,
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(named: "moreSelected"),
                style: .plain,
                target: self,
                action: #selector(moreTapped(button:))
            )
        }
    }
    
    private func setProgressView(_ percentage: Float) {
        activityIndicator.stopAnimating()
        progressView.isHidden = false
        progressView.setProgress(percentage, animated: true)
    }
    
    private func editFile() {
        viewModel.dispatch(.editFile)
        viewModel.dispatch(.setUpView)
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
            self.fileName = textEditorRenameAlertModel.textFileName
            textField.addTarget(self, action: #selector(self.renameAlertTextFieldBeginEdit), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(self.renameAlertTextFieldDidChange), for: .editingChanged)
        }
        renameAC.addAction(
            UIAlertAction(
                title: TextEditorL10n.cancel,
                style: .cancel,
                handler: nil
            )
        )
        let renameAction = UIAlertAction(
            title: TextEditorL10n.rename,
            style: .default,
            handler: { _ in
                guard let newInputName = renameAC.textFields?.first?.text else { return }
                if MEGAReachabilityManager.isReachableHUDIfNot() {
                    self.viewModel.dispatch(.renameFileTo(newInputName))
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
    
    @objc private func cancelTapped() {
        let discardChangesAC = UIAlertController().discardChanges(
            fromBarButton: navigationItem.leftBarButtonItem,
            withConfirmAction: {
                self.viewModel.dispatch(.cancel)
            }
        )
        present(discardChangesAC, animated: true, completion: nil)
    }
    
    @objc private func saveTapped() {
        viewModel.dispatch(.saveText(textView.text))
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
            textField.textColor = containsInvalidChars ? UIColor.mnz_redError() : UIColor.mnz_label()
            let empty = textField.text?.mnz_isEmpty() ?? true
            let noChange = textField.text == fileName
            rightButtonAction?.isEnabled = (!empty && !containsInvalidChars && !noChange)
        }
    }
}
