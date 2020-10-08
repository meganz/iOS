
import UIKit

class ContactsGroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newGroupChatLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!

    var searchController = UISearchController()
    var groupChats = [MEGAChatListItem]()
    var searchingGroupChats = [MEGAChatListItem]()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = AMLocalizedString("Groups", "Label for any ‘Groups’ button, link, text, title, etc. On iOS is used to go to the chats 'Groups' section from Contacts")
        newGroupChatLabel.text = AMLocalizedString("New Group Chat", "Text button for init a group chat")
        
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
        
        fetchGroupChatsList()
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
    
    //MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        separatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.reloadData()
    }

    func fetchGroupChatsList() {
        guard let chatListItems = MEGASdkManager.sharedMEGAChatSdk()?.chatListItems else {
            return
        }
        
        for i in 0..<chatListItems.size {
            guard let chatListItem = chatListItems.chatListItem(at: i) else {
                continue
            }
            if chatListItem.isGroup {
                groupChats.append(chatListItem)
            }
        }
        tableView.reloadData()
    }
    
    func addNewChatToList(chatRoom: MEGAChatRoom) {
        guard let newChatListItem = MEGASdkManager.sharedMEGAChatSdk()?.chatListItem(forChatId: chatRoom.chatId) else {
            return
        }
        groupChats.append(newChatListItem)
        if isSearching {
            updateSearchResults(for: searchController)
        } else {
            tableView.insertRows(at: [IndexPath(row: groupChats.count - 1, section: 0)], with: .automatic)
        }
    }
    
    func showGroupChatRoom(at indexPath: IndexPath) {
        let chatListItem = searchingGroupChats.count != 0 ? searchingGroupChats[indexPath.row] : groupChats[indexPath.row]
        guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        let messagesVC = ChatViewController()
        messagesVC.chatRoom = chatRoom;
        navigationController?.pushViewController(messagesVC, animated: true)
    }
    
    @IBAction func showNewChatGroup() {
        guard let contactsNavigation = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = contactsNavigation.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contactsMode = .chatCreateGroup
        contactsVC.createGroupChat = { [weak self] users, groupName, keyRotation, getChatlink in
            guard let users = users as? [MEGAUser] else {
                return
            }

            let messagesVC = ChatViewController()

            if keyRotation {
                MEGASdkManager.sharedMEGAChatSdk()?.mnz_createChatRoom(usersArray: users, title: groupName, completion: { chatRoom in
                    self?.addNewChatToList(chatRoom: chatRoom)
                    messagesVC.chatRoom = chatRoom
                    self?.navigationController?.pushViewController(messagesVC, animated: true)
                })
            } else {
                MEGASdkManager.sharedMEGAChatSdk()?.createPublicChat(withPeers: MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: users), title: groupName, delegate: MEGAChatGenericRequestDelegate.init(completion: { request, error in
                    guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: request.chatHandle) else {
                        return
                    }
                    self?.addNewChatToList(chatRoom: chatRoom)
                    messagesVC.chatRoom = chatRoom
                    if getChatlink {
                        MEGASdkManager.sharedMEGAChatSdk()?.createChatLink(messagesVC.chatRoom.chatId, delegate: MEGAChatGenericRequestDelegate.init(completion: { request, error in
                            if error.type == .MEGAChatErrorTypeOk {
                                messagesVC.publicChatWithLinkCreated = true
                                messagesVC.publicChatLink = URL(string: request.text)
                                self?.navigationController?.pushViewController(messagesVC, animated: true)
                            }
                        }))
                    } else {
                        self?.navigationController?.pushViewController(messagesVC, animated: true)
                    }
                }))
            }
        }
        present(contactsNavigation, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension ContactsGroupsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchingGroupChats.count : groupChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chatListItem = searchingGroupChats.count != 0 ? searchingGroupChats[indexPath.row] : groupChats[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath) as? ContactsGroupTableViewCell else {
            fatalError("Could not dequeue cell with identifier groupCell")
        }
        cell.configure(for: chatListItem)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactsGroupsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showGroupChatRoom(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - DZNEmptyDataSetSource

extension ContactsGroupsViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return EmptyStateView.init(image: imageForEmptyDataSet(), title: titleForEmptyDataSet(), description: nil, buttonTitle: nil)
    }
    
    private func imageForEmptyDataSet() -> UIImage? {
        if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
            return UIImage(named: "searchEmptyState")
        } else {
            return UIImage(named: "chatEmptyState")
        }
    }
    
    private func titleForEmptyDataSet() -> String? {
        if (self.searchController.isActive && self.searchController.searchBar.text!.count > 0) {
            return AMLocalizedString("noResults", "Title shown when you make a search and there is 'No Results'")
        } else {
            return AMLocalizedString("noConversations", "Empty Conversations section")
        }
    }
}

// MARK: - UISearchResultsUpdating

extension ContactsGroupsViewController: UISearchResultsUpdating {
    
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
                searchingGroupChats.removeAll()
            } else {
                searchingGroupChats = groupChats.filter({$0.chatTitle().contains(searchString)})
            }
        }
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate

extension ContactsGroupsViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchingGroupChats.removeAll()
    }
}
