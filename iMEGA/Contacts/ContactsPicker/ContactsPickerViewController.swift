
import UIKit

@objc protocol ContactsPickerViewControllerDelegate {
    func contactsPicker(_ contactsPicker: ContactsPickerViewController, didSelect values: [String]) ->  ()
}

class ContactsPickerViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private lazy var searchController = UISearchController()
    
    private var keys = [String]()

    private var contacts = [DeviceContact]()
    private var contactsSections = [String: [DeviceContact]]()
    private var contactsSectionTitles = [String]()
    private lazy var searchingContacts = [DeviceContact]()
    
    private var delegate: ContactsPickerViewControllerDelegate?

    private lazy var selectAllBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "selectAll"), style: .plain, target: self, action: #selector(selectAllTapped)
    )
    
    private lazy var sendBarButton: UIBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(sendTapped)
    )
    
    @objc class func instantiate(for keys: [String], delegate: ContactsPickerViewControllerDelegate) -> ContactsPickerViewController {
        guard let contactsPickerVC = UIStoryboard(name: "ContactsPicker", bundle: nil).instantiateViewController(withIdentifier: "ContactsPickerViewControllerID") as? ContactsPickerViewController else {
            fatalError("Could not instantiate ContactsPickerViewController")
        }
        SVProgressHUD.show()

        contactsPickerVC.keys = keys
        contactsPickerVC.delegate = delegate
        return contactsPickerVC
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contacts = DeviceContactsManager().getDeviceContacts(for: keys)

        title = AMLocalizedString("contactsTitle", "Title of the Contacts section")
        
        guard let megaNavigation = navigationController as? MEGANavigationController else {
            fatalError("Could not access MEGANavigationController")
        }
        megaNavigation.addLeftDismissButton(withText: AMLocalizedString("cancel"))
        
        navigationItem.rightBarButtonItem = selectAllBarButton
        
        contactsSections = Dictionary(grouping: contacts, by: {String($0.name.uppercased().prefix(1))})
        contactsSectionTitles = contactsSections.keys.sorted()

        searchController = Helper.customSearchController(withSearchResultsUpdaterDelegate: self, searchBarDelegate: self)
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.barTintColor = .white
            tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.height)
        }
        
        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
        updateAppearance()
        
        let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flexibleSpaceBarButton, sendBarButton]
        
        SVProgressHUD.dismiss()
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
    
    // MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.reloadData()
    }
    
    @objc private func sendTapped() {
        
        dismiss(animated: true) {
            self.delegate?.contactsPicker(self, didSelect: self.contacts.filter( { $0.isSelected } ).map( { $0.value } ))
        }
    }
    
    @objc private func selectAllTapped() {
        if contacts.count == tableView.indexPathsForSelectedRows?.count {
            contacts.forEach({ $0.isSelected = false })
            for section in 0..<tableView.numberOfSections {
                let numberOfRows = tableView.numberOfRows(inSection: section)
                for row in 0..<numberOfRows {
                    tableView.deselectRow(at: IndexPath(row: row, section: section), animated: false)
                }
            }
            navigationController?.setToolbarHidden(true, animated: true)
        } else {
            contacts.forEach({ $0.isSelected = true })
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
        
        if contact.isSelected {
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
        
        contact.isSelected = true
        if contacts.filter({ $0.isSelected }).count == 1 {
            navigationController?.setToolbarHidden(false, animated: true)
        }
        updateToolbar()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let contact = isSearching ? searchingContacts[indexPath.row] : contactsSections[contactsSectionTitles[indexPath.section]]?[indexPath.row] else {
            fatalError("Could not get device contact at index path")
        }
                
        contact.isSelected = false
        if contacts.filter({ $0.isSelected }).count == 0 {
            navigationController?.setToolbarHidden(true, animated: true)
        }
        updateToolbar()
    }
    
    func updateToolbar() {
        sendBarButton.title = String(format: "%@ (%d)", AMLocalizedString("send", "Label for any 'Send' button, link, text, title, etc. - (String as short as possible)."), contacts.filter({ $0.isSelected }).count)
    }
}

// MARK: - DZNEmptyDataSetSource

extension ContactsPickerViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return EmptyStateView.init(image: imageForEmptyDataSet(), title: titleForEmptyDataSet(), description: nil, buttonTitle: nil)
    }
    
    func imageForEmptyDataSet() -> UIImage? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
                return UIImage(named: "searchEmptyState")
            } else {
                return UIImage(named: "contactsEmptyState")
            }
        } else {
            return UIImage(named: "noInternetEmptyState")
        }
    }
    
    func titleForEmptyDataSet() -> String? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
                return AMLocalizedString("noResults", "Title shown when you make a search and there is 'No Results'")
            } else {
                return AMLocalizedString("contactsEmptyState_title", "Title shown when the Contacts section is empty, when you have not added any contact.")
            }
        } else {
            return AMLocalizedString("noInternetConnection", "No Internet Connection")
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
}
