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

        navigationItem.title = NSLocalizedString("On MEGA", comment: "Text used as a section title or similar showing the user the phone contacts using MEGA")
        inviteContactLabel.text = NSLocalizedString("inviteContact", comment: "Text shown when the user tries to make a call and the receiver is not a contact")
        
        searchController = Helper.customSearchController(withSearchResultsUpdaterDelegate: self, searchBarDelegate: self)
        searchController.hidesNavigationBarDuringPresentation = false
        
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
        tableView.register(ContactsPermissionBottomView().nib(), forHeaderFooterViewReuseIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier())

        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
        
        updateAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
        self.tableView.layoutIfNeeded()
        tableView.reloadData()
        showSearch()
        
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
        navigationItem.searchController = nil
        
        inviteContactView.isHidden = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [unowned self] _ in
            self.tableView.reloadData()
            self.searchController.searchBar.frame.size.width = self.searchFixedView.frame.size.width
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
        }
    }
    
    // MARK: - Private
    
    func updateAppearance() {
        view.backgroundColor = (presentingViewController == nil) ? .mnz_backgroundGrouped(for: traitCollection) : .mnz_backgroundGroupedElevated(traitCollection)
        tableView.backgroundColor = (presentingViewController == nil) ? .mnz_backgroundGrouped(for: traitCollection) : .mnz_backgroundGroupedElevated(traitCollection)
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        
        inviteContactView.backgroundColor = (presentingViewController == nil) ? .mnz_secondaryBackgroundGrouped(traitCollection) : .mnz_secondaryBackgroundElevated(traitCollection)
        
        tableView.reloadData()
    }
    
    private func contacts() -> [ContactOnMega] {
        return (searchController.isActive && searchController.searchBar.text != "") ? searchingContactsOnMega : contactsOnMega
    }
    
    private func showSearch() {
        let shouldSearchBarBeHidden = inviteContactView.isHidden || contacts().count == 0 || CNContactStore.authorizationStatus(for: CNEntityType.contacts) != CNAuthorizationStatus.authorized
        searchFixedView?.isHidden = true
        navigationItem.searchController = shouldSearchBarBeHidden ? nil : searchController
    }
    
    // MARK: Actions
    @IBAction func inviteContactButtonTapped(_ sender: Any) {
        if searchController.isActive {
            searchController.isActive = false
        }
        
        guard let inviteContactVC = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "InviteContactViewControllerID") as? InviteContactViewController else { return }
        
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
                searchingContactsOnMega = contactsOnMega.filter({$0.name.contains(searchString)})
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
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        header.titleLabel.text = NSLocalizedString("CONTACTS ON MEGA", comment: "Text used as a section title or similar showing the user the phone contacts using MEGA")
        
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case .notDetermined:
            guard let bottomView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ContactsPermissionBottomView().bottomReuserIdentifier()) as? ContactsPermissionBottomView else {
                return UIView(frame: .zero)
            }
            bottomView.configureForRequestingPermission( action: {
                DevicePermissionsHelper.contactsPermission { (granted) in
                    if granted {
                        ContactsOnMegaManager.shared.configureContactsOnMega(completion: {
                            self.contactsOnMega = ContactsOnMegaManager.shared.fetchContactsOnMega() ?? []
                            tableView.reloadData()
                            //FIXME: The search bar does not appear after grating the Contacts permissions
                            self.showSearch()
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
            return tableView.frame.height * 0.95
            
        default:
            return 0
        }
    }
}

// MARK: - DZNEmptyDataSetSource

extension ContactsOnMegaViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        let emptyStateView = EmptyStateView.init(image: imageForEmptyDataSet(), title: titleForEmptyDataSet(), description: nil, buttonTitle: nil)
        
        return emptyStateView
    }
    
    func imageForEmptyDataSet() -> UIImage? {
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
    
    func titleForEmptyDataSet() -> String? {
        if (MEGAReachabilityManager.isReachable()) {
            if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
                return NSLocalizedString("noResults", comment: "Title shown when you make a search and there is 'No Results'")
            } else {
                return nil
            }
        } else {
            return NSLocalizedString("noInternetConnection", comment: "No Internet Connection")
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
