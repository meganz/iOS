import MEGAL10n

// MARK: UITableViewDelegate
extension SettingsTableViewController {
    
    @objc func bindViewModel() {
        self.viewModel.invokeCommand = { [weak self] cmd in
            switch cmd {
            case .reloadData:
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        super.numberOfSections(in: tableView)
        return viewModel.numberOfSections()
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        super.numberOfSections(in: tableView)
        return viewModel.numberOfRows(in: section)
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        super.tableView(tableView, cellForRowAt: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.classNameString, for: indexPath) as! SettingsTableViewCell
        if let cellVm = viewModel.cellViewModel(at: indexPath.section, in: indexPath.row) {
            cell.update(viewModel: cellVm)
        }
        return cell
    }
    
    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.mnz_backgroundElevated()
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.dispatch(.didSelect(section: indexPath.section, row: indexPath.row))
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Delete account
extension SettingsTableViewController {
    
    @objc func showDeleteAccountEmailConfirmationView() {
        let awaitingEmailConfirmationView = AwaitingEmailConfirmationView.instanceFromNib
        awaitingEmailConfirmationView.titleLabel.text = Strings.Localizable.awaitingEmailConfirmation
        awaitingEmailConfirmationView.descriptionLabel.text = Strings.Localizable.ifYouCantAccessYourEmailAccount
        awaitingEmailConfirmationView.frame = self.view.bounds
        self.view = awaitingEmailConfirmationView
    }
}

// MARK: - MEGARequestDelegate
extension SettingsTableViewController: MEGARequestDelegate {
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        switch request.type {
        case .MEGARequestTypeGetCancelLink:
            guard error.type == .apiOk else { return }
            showDeleteAccountEmailConfirmationView()
        default:
            return
        }
    }
}
