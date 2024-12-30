import ChatRepo
import MEGADesignToken
import MEGAL10n
import MEGAUIKit
import UIKit

class ContactsGroupsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newGroupChatView: UIView!
    @IBOutlet weak var newGroupChatImageView: UIImageView!
    @IBOutlet weak var newGroupChatLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var disclosureIndicatorImageView: UIImageView!
    
    var searchController = UISearchController()
    var groupChats = [MEGAChatListItem]()
    var searchingGroupChats = [MEGAChatListItem]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.Localizable.groups
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: Strings.Localizable.groups)
        newGroupChatLabel.text = Strings.Localizable.newGroupChat
        newGroupChatImageView.image = UIImage.groupChatToken
        
        searchController = UISearchController.customSearchController(searchResultsUpdaterDelegate: self, searchBarDelegate: self)
        navigationItem.searchController = searchController
        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
        
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar, 
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                               traitCollection: traitCollection)
        
        setupColors()
        
        fetchGroupChatsList()
    }
    
    // MARK: - Private
    
    private func setupColors() {
        newGroupChatLabel.textColor = TokenColors.Text.primary
        view.backgroundColor = TokenColors.Background.page
        newGroupChatView.backgroundColor = TokenColors.Background.page
        separatorView.backgroundColor = TokenColors.Border.strong
        tableView.separatorColor = TokenColors.Border.strong
        disclosureIndicatorImageView.image =  UIImage(resource: .disclosure)
    }

    func fetchGroupChatsList() {
        guard let chatListItems = MEGAChatSdk.shared.chatListItems else {
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
        guard let newChatListItem = MEGAChatSdk.shared.chatListItem(forChatId: chatRoom.chatId) else {
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
        let chatListItem = searchingGroupChats.isNotEmpty ? searchingGroupChats[indexPath.row] : groupChats[indexPath.row]
        guard let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        ChatContentRouter(chatRoom: chatRoom.toChatRoomEntity(), presenter: navigationController).start()
    }
    
    @IBAction func showNewChatGroup() {
        guard let contactsNavigation = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = contactsNavigation.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contactsMode = .chatCreateGroup
        contactsVC.createGroupChat = { [weak self] users, groupName, keyRotation, getChatlink, allowNonHostToAddParticipants in
            guard let users = users as? [MEGAUser] else {
                return
            }
            
            if keyRotation {
                MEGAChatSdk.shared.mnz_createChatRoom(
                    usersArray: users,
                    title: groupName,
                    allowNonHostToAddParticipants: allowNonHostToAddParticipants,
                    completion: { chatRoom in
                        DispatchQueue.main.async {
                            self?.addNewChatToList(chatRoom: chatRoom)
                            ChatContentRouter(chatRoom: chatRoom.toChatRoomEntity(), presenter: self?.navigationController).start()
                        }
                    })
            } else {
                MEGAChatSdk.shared.createPublicChat(
                    withPeers: MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: users),
                    title: groupName,
                    speakRequest: false,
                    waitingRoom: false,
                    openInvite: allowNonHostToAddParticipants,
                    delegate: ChatRequestDelegate { result in
                        guard case let .success(request) = result,
                              let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: request.chatHandle) else {
                            return
                        }
                        DispatchQueue.main.async {
                            self?.addNewChatToList(chatRoom: chatRoom)
                        }
                        if getChatlink {
                            MEGAChatSdk.shared.createChatLink(chatRoom.chatId, delegate: ChatRequestDelegate { result in
                                if case .success = result, let text = request.text {
                                    guard let self else { return }
                                    ChatContentRouter(chatRoom: chatRoom.toChatRoomEntity(), presenter: self.navigationController, publicLink: text, showShareLinkViewAfterOpenChat: true).start()
                                }
                            })
                        } else {
                            DispatchQueue.main.async {
                                guard let self else { return }
                                ChatContentRouter(chatRoom: chatRoom.toChatRoomEntity(), presenter: self.navigationController).start()
                            }
                        }
                    })
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
        let chatListItem = searchingGroupChats.isNotEmpty ? searchingGroupChats[indexPath.row] : groupChats[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath) as? ContactsGroupTableViewCell else {
            fatalError("Could not dequeue cell with identifier groupCell")
        }
        cell.configure(with: chatListItem.toChatListItemEntity())
        
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
        if self.searchController.isActive && self.searchController.searchBar.text?.isNotEmpty == true {
            return UIImage.searchEmptyState
        } else {
            return UIImage.chatEmptyState
        }
    }
    
    private func titleForEmptyDataSet() -> String? {
        if self.searchController.isActive && self.searchController.searchBar.text?.isNotEmpty == true {
            return Strings.Localizable.noResults
        } else {
            return Strings.Localizable.noConversations
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
