
import Contacts
import UIKit


@objc class ContactsOnMegaViewController: UIViewController {

    var searchController = UISearchController()
    var contactsOnMega = [ContactOnMega]()
    var searchingContactsOnMega = [ContactOnMega]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inviteContactView: UIStackView!
    @IBOutlet weak var inviteContactLabel: UILabel!
    @IBOutlet weak var searchFixedView: UIView!
    @IBOutlet var contactsOnMegaHeader: UIView!
    @IBOutlet weak var contactsOnMegaHeaderTitle: UILabel!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Contacts on MEGA", comment: "Text used as a section title or similar showing the user the phone contacts using MEGA")
        inviteContactLabel.text = NSLocalizedString("inviteContact", comment: "Text shown when the user tries to make a call and the receiver is not a contact")
        searchController = Helper.customSearchController(withSearchResultsUpdaterDelegate: self, searchBarDelegate: self)
        self.searchController.hidesNavigationBarDuringPresentation = false
        searchFixedView.addSubview(searchController.searchBar)
        
        tableView.register(ContactsPermissionBottomView().nib(), forHeaderFooterViewReuseIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier())
        
        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
        tableView.reloadData()
    }
    
    func hideSearchAndInviteViews() {
        searchFixedView.isHidden = true
        inviteContactView.isHidden = true
    }
    
    // MARK: Private
    private func contacts() -> [ContactOnMega] {
        return (searchController.isActive && searchController.searchBar.text != "") ? searchingContactsOnMega : contactsOnMega
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
        guard let searchString = searchController.searchBar.text else { return }
        if searchController.isActive {
            if searchString == "" {
                searchingContactsOnMega.removeAll()
            } else {
                searchingContactsOnMega = contactsOnMega.filter( {$0.name.contains(searchString)} )
            }
        }
        self.tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension ContactsOnMegaViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchingContactsOnMega.removeAll()
        if !MEGAReachabilityManager.isReachable() {
            searchFixedView.isHidden = true
        }
    }
}

// MARK: - UITableViewDataSource
extension ContactsOnMegaViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if CNContactStore.authorizationStatus(for: CNEntityType.contacts) == CNAuthorizationStatus.authorized {
            return contacts().count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "contactOnMegaCell", for: indexPath) as? ContactOnMegaTableViewCell else {
            fatalError("Could not dequeue cell with identifier contactOnMegaCell")
        }
        
        cell.configure(for: contacts()[indexPath.row])
        
        return cell
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
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case .notDetermined, .restricted, .denied:
            return tableView.frame.height
            
        default:
            return 0
        }
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
