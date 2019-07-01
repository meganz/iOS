
import Contacts
import UIKit


@objc class ContactsOnMegaViewController: UIViewController {

    var searchController = UISearchController()
    var contactsOnMega = [Any]()
    var searchingContactsOnMega = [Any]()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchFixedView: UIView!
    @IBOutlet var contactsOnMegaHeader: UIView!
    @IBOutlet weak var contactsOnMegaHeaderTitle: UILabel!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Contacts on MEGA", comment: "Text used as a section title or similar showing the user the phone contacts using MEGA")
        
        searchController = Helper.customSearchController(withSearchResultsUpdaterDelegate: self, searchBarDelegate: self)
        self.searchController.hidesNavigationBarDuringPresentation = false
        searchFixedView.addSubview(searchController.searchBar)
        
        tableView.register(ContactsPermissionBottomView().nib(), forHeaderFooterViewReuseIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
        tableView.reloadData()
    }
    
    // MARK: Private
    private func numberOfContacts() -> NSInteger {
        return searchController.isActive ? searchingContactsOnMega.count : contactsOnMega.count
    }
    
    // MARK: Actions
    @IBAction func inviteContactButtonTapped(_ sender: Any) {
        if searchController.isActive {
            searchController.isActive = false
        }
        
        guard let inviteContactVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "InviteContactViewControllerID") as? InviteContactViewController else { return }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(inviteContactVC, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension ContactsOnMegaViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        if searchController.isActive {
            if searchString == "" {
                searchingContactsOnMega.removeAll()
            } else {
                //TODO: filter swifty way
//                let predicate = NSPredicate(format: "SELF.mnz_fullname contains[c] %@", searchString!)
//                searchingContactsOnMega = contactsOnMega.filtered(using: predicate)
            }
        }
        self.tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension ContactsOnMegaViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchingContactsOnMega.removeAll()
        if MEGAReachabilityManager.isReachable() {
            searchFixedView.isHidden = true
        }
    }
}

// MARK: - UITableViewDataSource
extension ContactsOnMegaViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if CNContactStore.authorizationStatus(for: CNEntityType.contacts) == CNAuthorizationStatus.authorized {
            return numberOfContacts()
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "contactOnMegaCell", for: indexPath)
    }
}

// MARK: - UITableViewDelegate
extension ContactsOnMegaViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        contactsOnMegaHeaderTitle.text = NSLocalizedString("Contacts on MEGA", comment: "Text used as a section title or similar showing the user the phone contacts using MEGA").uppercased()
        return contactsOnMegaHeader
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case .notDetermined:
            guard let bottomView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier()) as? ContactsPermissionBottomView else {
                return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            }
            bottomView.configureForRequestingPermission ( action: {
                DevicePermissionsHelper.contactsPermission { (granted) in
                    if granted {
                        ContactsOnMegaManager.shared.configureContactsOnMega(completion: {
                            self.contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
                            tableView.reloadData()
                        })
                    }
                }
            })
            return bottomView
            
        case .restricted, .denied:
            guard let bottomView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier()) as? ContactsPermissionBottomView else {
                return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            }
            bottomView.configureForOpenSettingsPermission( action: {
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            })
            
            return bottomView
            
        case .authorized:
            return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            
        @unknown default:
            return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            
        }
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableView.frame.height
    }
}

// MARK: - DZNEmptyDataSetSource
extension ContactsOnMegaViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive ) {
                if (self.searchController.searchBar.text!.count > 0) {
                    return UIImage(named: "searchEmptyState")
                } else {
                    return nil
                }
            } else {
                return UIImage(named: "contactsEmptyState")
            }
        } else {
            return UIImage(named: "noInternetEmptyState")
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive ) {
                if (self.searchController.searchBar.text!.count > 0) {
                    return NSAttributedString(string: NSLocalizedString("noResults", comment: "Title shown when you make a search and there is 'No Results'"))
                } else {
                    return nil
                }
            } else {
                return NSAttributedString(string: NSLocalizedString("contactsEmptyState_title", comment: "Title shown when the Contacts section is empty, when you have not added any contact."))
            }
        } else {
            return NSAttributedString(string: NSLocalizedString("noInternetConnection", comment: "No Internet Connection"))
        }
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (MEGAReachabilityManager.isReachable()) {
            if (!self.searchController.isActive) {
                return NSAttributedString(string: NSLocalizedString("Invite contacts and start chatting securely with MEGA’s encrypted chat.", comment: "Text encouraging the user to invite contacts to MEGA"))
            }
        }
        return nil
    }
}
