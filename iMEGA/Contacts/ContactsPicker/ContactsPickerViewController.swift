
import UIKit

@objc protocol ContactsPickerViewControllerDelegate {
    func contactsPicker(_ contactsPicker: ContactsPickerViewController, didSelectContacts values: [String])
}

class ContactsPickerViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private lazy var searchController = UISearchController()
    
    private var keys = [String]()

    private var contacts = [DeviceContact]()
    private var deviceContactsOperation: DeviceContactsOperation?

    private var contactsSections = [String: [DeviceContact]]()
    private var contactsSectionTitles = [String]()
    private lazy var searchingContacts = [DeviceContact]()
    private lazy var selectedContacts = Set<DeviceContact>()

    private var delegate: ContactsPickerViewControllerDelegate?

    private lazy var selectAllBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "selectAll"), style: .plain, target: self, action: #selector(selectAllTapped)
    )
    
    private lazy var sendBarButton: UIBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(sendTapped)
    )
    
    @objc class func instantiate(withContactKeys keys: [String], delegate: ContactsPickerViewControllerDelegate) -> ContactsPickerViewController {
        guard let contactsPickerVC = UIStoryboard(name: "ContactsPicker", bundle: nil).instantiateViewController(withIdentifier: "ContactsPickerViewControllerID") as? ContactsPickerViewController else {
            fatalError("Could not instantiate ContactsPickerViewController")
        }

        contactsPickerVC.keys = keys
        contactsPickerVC.delegate = delegate
        return contactsPickerVC
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.presentationController?.delegate = self

        configureView()
        fetchDeviceContacts()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                AppearanceManager.forceSearchBarUpdate(searchController.searchBar, traitCollection: traitCollection)

                updateAppearance()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let operation = deviceContactsOperation, operation.isExecuting {
            SVProgressHUD.dismiss()
            DeviceContactsManager.shared.cancelDeviceContactsOperation(operation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Private
    
    private func addSearchController() {
        searchController = Helper.customSearchController(withSearchResultsUpdaterDelegate: self, searchBarDelegate: self)
        searchController.hidesNavigationBarDuringPresentation = false
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.barTintColor = .white
            tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.height)
        }
    }
    
    private func configureView() {
        title = AMLocalizedString("contactsTitle", "Title of the Contacts section")
        guard let megaNavigation = navigationController as? MEGANavigationController else {
            fatalError("Could not access MEGANavigationController")
        }
        megaNavigation.addLeftDismissButton(withText: AMLocalizedString("cancel"))
        
        navigationItem.rightBarButtonItem = selectAllBarButton
        selectAllBarButton.isEnabled = false
        
        addSearchController()

        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
        updateAppearance()
        
        let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flexibleSpaceBarButton, sendBarButton]
    }
    
    private func fetchDeviceContacts() {
        SVProgressHUD.show(withStatus: AMLocalizedString("loading", "state previous to import a file"))
        
        let deviceContactsOperation = DeviceContactsOperation(keys)
        deviceContactsOperation.completionBlock = { [weak self] in
            if deviceContactsOperation.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self?.prepareDataSource(forContacts: deviceContactsOperation.fetchedContacts)
                SVProgressHUD.dismiss()
                self?.selectAllBarButton.isEnabled = true
            }
        }
        
        DeviceContactsManager.shared.addGetDeviceContactsOperation(deviceContactsOperation)
        
        self.deviceContactsOperation = deviceContactsOperation
    }
    
    private func prepareDataSource(forContacts fetchedContacts: [DeviceContact]) {
        contacts = fetchedContacts
        contactsSections = Dictionary(grouping: contacts, by: {String($0.name.uppercased().prefix(1))})
        contactsSectionTitles = contactsSections.keys.sorted()
        tableView.emptyDataSetSource = self
        tableView.reloadData()
    }
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.reloadData()
    }
    
    @objc private func sendTapped() {
        dismiss(animated: true) {
            self.delegate?.contactsPicker(self, didSelectContacts: self.selectedContacts.map( { $0.contactDetail } ))
        }
    }
    
    @objc private func selectAllTapped() {
        if contacts.count == tableView.indexPathsForSelectedRows?.count {
            selectedContacts.removeAll()
            for section in 0..<tableView.numberOfSections {
                let numberOfRows = tableView.numberOfRows(inSection: section)
                for row in 0..<numberOfRows {
                    tableView.deselectRow(at: IndexPath(row: row, section: section), animated: false)
                }
            }
            navigationController?.setToolbarHidden(true, animated: true)
        } else {
            selectedContacts = Set(contacts)
            for section in 0..<tableView.numberOfSections {
                let numberOfRows = tableView.numberOfRows(inSection: section)
                for row in 0..<numberOfRows {
                    tableView.selectRow(at: IndexPath(row: row, section: section), animated: false, scrollPosition: .none)
                }
            }
            if navigationController?.isToolbarHidden ?? true {
                navigationController?.setToolbarHidden(false, animated: true)
            }
        }
        updateToolbar()
    }
    
    @objc func emptyStateButtonTouchUpInside() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}

// MARK: - UITableViewDataSource

extension ContactsPickerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : contactsSectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchingContacts.count : contactsSections[contactsSectionTitles[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let contact = isSearching ? searchingContacts[indexPath.row] : contactsSections[contactsSectionTitles[indexPath.section]]?[indexPath.row] else {
            fatalError("Could not get device contact at index path")
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeviceContactTableViewCell.reuseIdentifier, for: indexPath) as? DeviceContactTableViewCell else {
            fatalError("Could not dequeue cell with identifier deviceContactCell")
        }
        cell.configure(for: contact)
        
        if selectedContacts.contains(contact) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearching ? nil : contactsSectionTitles[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isSearching ? nil : contactsSectionTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return contactsSectionTitles.firstIndex(of: title) ?? 0
    }
}

// MARK: - UITableViewDelegate

extension ContactsPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let contact = isSearching ? searchingContacts[indexPath.row] : contactsSections[contactsSectionTitles[indexPath.section]]?[indexPath.row] else {
            fatalError("Could not get device contact at index path")
        }
        
        selectedContacts.insert(contact)
        if selectedContacts.count == 1 {
            navigationController?.setToolbarHidden(false, animated: true)
        }
        updateToolbar()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let contact = isSearching ? searchingContacts[indexPath.row] : contactsSections[contactsSectionTitles[indexPath.section]]?[indexPath.row] else {
            fatalError("Could not get device contact at index path")
        }
               
        selectedContacts.remove(contact)
        if selectedContacts.count == 0 {
            navigationController?.setToolbarHidden(true, animated: true)
        }
        updateToolbar()
    }
    
    func updateToolbar() {
        sendBarButton.title = String(format: "%@ (%d)", AMLocalizedString("send", "Label for any 'Send' button, link, text, title, etc. - (String as short as possible)."), selectedContacts.count)
    }
}

// MARK: - DZNEmptyDataSetSource

extension ContactsPickerViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        let emptyStateView = EmptyStateView.init(image: imageForEmptyDataSet(), title: titleForEmptyDataSet(), description: nil, buttonTitle: buttonTitleForEmptyDataSet())
        emptyStateView.button?.addTarget(self, action: #selector(emptyStateButtonTouchUpInside), for: .touchUpInside)
        return emptyStateView
    }
    
    func imageForEmptyDataSet() -> UIImage? {
        if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
            return UIImage(named: "searchEmptyState")
        } else {
            return UIImage(named: "contactsEmptyState")
        }
    }
    
    func titleForEmptyDataSet() -> String? {
        if CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .authorized {
            if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
                return AMLocalizedString("noResults", "Title shown when you make a search and there is 'No Results'")
            } else {
                return AMLocalizedString("contactsEmptyState_title", "Title shown when the Contacts section is empty, when you have not added any contact.")
            }
        } else {
            return AMLocalizedString("Enable Access to Your Address Book", "Title label that explains that the user is going to be asked for the contacts permission")
        }
    }
    
    func buttonTitleForEmptyDataSet() -> String? {
        if CNContactStore.authorizationStatus(for: CNEntityType.contacts) != .authorized {
            return AMLocalizedString("Open Settings", "Text indicating the user to open the device settings for MEGA")
        } else {
            return nil
        }
    }
}

// MARK: - UISearchResultsUpdating

extension ContactsPickerViewController: UISearchResultsUpdating {
    
    var isSearching: Bool {
        searchController.isActive && !isSearchBarEmpty
    }
    
    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
        if searchController.isActive {
            if searchString == "" {
                searchingContacts.removeAll()
            } else {
                searchingContacts = contacts.filter({$0.name.contains(searchString)})
            }
        }
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate

extension ContactsPickerViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchingContacts.removeAll()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        contacts.count > 0
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ContactsPickerViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        selectedContacts.count == 0
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        let discardChangesActionSheet = UIAlertController().discardChanges(fromSourceView: navigationController?.view, sourceRect: CGRect(x: 20, y: 20, width: 1, height: 1), withConfirmAction: {
            self.dismiss(animated: true, completion: nil)
        })
        present(discardChangesActionSheet, animated: true, completion: nil)
    }
}
