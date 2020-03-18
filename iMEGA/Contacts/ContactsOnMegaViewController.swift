
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
        
        navigationItem.title = AMLocalizedString("On MEGA", "Text used as a section title or similar showing the user the phone contacts using MEGA")
        inviteContactLabel.text = AMLocalizedString("inviteContact", "Text shown when the user tries to make a call and the receiver is not a contact")
        searchController = Helper.customSearchController(withSearchResultsUpdaterDelegate: self, searchBarDelegate: self)
        self.searchController.hidesNavigationBarDuringPresentation = false
        searchFixedView.addSubview(searchController.searchBar)
        
        tableView.register(ContactsPermissionBottomView().nib(), forHeaderFooterViewReuseIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier())
        
        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
        self.tableView.layoutIfNeeded()
        tableView.reloadData()
        searchFixedView.isHidden = inviteContactView.isHidden || contacts().count == 0 || CNContactStore.authorizationStatus(for: CNEntityType.contacts) != CNAuthorizationStatus.authorized
        
        if ContactsOnMegaManager.shared.state == ContactsOnMegaManager.ContactsOnMegaState.fetching {
            SVProgressHUD.show()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Fix to avoid ContactsPermissionBottomView button not being rendered correctly in small screens and iOS10
        if CNContactStore.authorizationStatus(for: CNEntityType.contacts) != CNAuthorizationStatus.authorized {
            tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
    }
    
    func hideSearchAndInviteViews() {
        searchFixedView.isHidden = true
        inviteContactView.isHidden = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { [unowned self] _ in
            self.tableView.reloadData()
            self.searchController.searchBar.frame.size.width = self.searchFixedView.frame.size.width
        }
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
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension ContactsOnMegaViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchingContactsOnMega.removeAll()
        if !MEGAReachabilityManager.isReachable() {
            searchFixedView.isHidden = true
        }
        self.searchController.searchBar.frame.size.width = self.searchFixedView.frame.size.width
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
        
        cell.configure(for: contacts()[indexPath.row], delegate: self)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContactsOnMegaViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        contactsOnMegaHeaderTitle.text = AMLocalizedString("CONTACTS ON MEGA", "Text used as a section title or similar showing the user the phone contacts using MEGA")
        return contactsOnMegaHeader
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case .notDetermined:
            guard let bottomView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier()) as? ContactsPermissionBottomView else {
                return UIView(frame: .zero)
            }
            bottomView.configureForRequestingPermission ( action: {
                SVProgressHUD.show()
                DevicePermissionsHelper.contactsPermission { (granted) in
                    if granted {
                        ContactsOnMegaManager.shared.configureContactsOnMega(completion: {
                            self.contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
                            tableView.reloadData()
                            self.searchFixedView.isHidden = self.inviteContactView.isHidden
                            SVProgressHUD.dismiss()
                        })
                    } else {
                        tableView.reloadData()
                        SVProgressHUD.dismiss()
                    }
                }
            })
            return bottomView
            
        case .restricted, .denied:
            guard let bottomView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier()) as? ContactsPermissionBottomView else {
                return UIView(frame: CGRect.zero)
            }
            bottomView.configureForOpenSettingsPermission( action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            })
            
            return bottomView
            
        case .authorized:
            return UIView(frame: CGRect.zero)
            
        @unknown default:
            return UIView(frame: CGRect.zero)
        }
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case .notDetermined, .restricted, .denied:
            return tableView.frame.height * 0.9
            
        default:
            return 0
        }
    }
}

// MARK: - DZNEmptyDataSetSource
extension ContactsOnMegaViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
                return UIImage(named: "searchEmptyState")
            } else {
                return nil
            }
        } else {
            return UIImage(named: "noInternetEmptyState")
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
                return NSAttributedString(string: AMLocalizedString("noResults", "Title shown when you make a search and there is 'No Results'"))
            } else {
                return nil
            }
        } else {
            return NSAttributedString(string: AMLocalizedString("noInternetConnection", "No Internet Connection"))
        }
    }
}

// MARK: - ContactOnMegaTableViewCellDelegate
extension ContactsOnMegaViewController: ContactOnMegaTableViewCellDelegate {
    func addContactCellTapped(_ cell: ContactOnMegaTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        contactsOnMega.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        if contactsOnMega.count == 0 {
            tableView.reloadEmptyDataSet()
        }
    }
}
