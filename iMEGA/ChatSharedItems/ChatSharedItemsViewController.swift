
import UIKit

class ChatSharedItemsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var attachmentsLoaded = false
    private var attachmentsLoading = false

    private var chatRoom = MEGAChatRoom()
    private lazy var messagesArray = [MEGAChatMessage]()

    private lazy var cancelBarButton: UIBarButtonItem = UIBarButtonItem(title: AMLocalizedString("cancel", "Button title to cancel something"), style: .plain, target: self, action: #selector(cancelSelectTapped)
    )
    
    private lazy var selectBarButton: UIBarButtonItem = UIBarButtonItem(title: AMLocalizedString("select", "Button that allows you to select something"), style: .plain, target: self, action: #selector(selectTapped)
    )
    
    private lazy var selectAllBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "selectAll"), style: .plain, target: self, action: #selector(selectAllTapped)
    )
    
    private lazy var forwardBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "forwardToolbar"), style: .plain, target: self, action: #selector(forwardTapped)
    )
    
    private lazy var downloadBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "download"), style: .plain, target: self, action: #selector(downloadTapped)
    )
    
    private lazy var importBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "import"), style: .plain, target: self, action: #selector(importTapped)
    )
    
    private lazy var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)

    // MARK: - Init methods
    
    @objc class func instantiate(with chatRoom: MEGAChatRoom) -> ChatSharedItemsViewController {
        let controller = UIStoryboard(name: "ChatSharedItems", bundle: nil).instantiateViewController(withIdentifier: "ChatSharedItemsID") as! ChatSharedItemsViewController
        controller.chatRoom = chatRoom
        return controller
    }
    
    // MARK: - View controller Lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = AMLocalizedString("sharedItems", "Title of Shared Items section")
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: CGFloat.leastNormalMagnitude))
        
        MEGASdkManager.sharedMEGAChatSdk()?.openNodeHistory(forChat: chatRoom.chatId, delegate: self)
        
        loadMoreFiles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        MEGASdkManager.sharedMEGAChatSdk()?.closeNodeHistory(forChat: chatRoom.chatId, delegate: self)

        super.viewWillDisappear(animated)
    }
    
    // MARK: - Actions
    
    @IBAction func actionsTapped(_ sender: UIButton) {
        let position = sender.convert(CGPoint.zero, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: position), let node = messagesArray[indexPath.row].nodeList.node(at: 0) else {
            return
        }
        
        let nodeActions = NodeActionViewController(node: node, delegate: self, displayMode: .chatSharedFiles, sender: sender)
        present(nodeActions, animated: true, completion: nil)
    }
    
    @objc private func selectTapped() {
        title = AMLocalizedString("selectTitle", "Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos")
        tableView.setEditing(true, animated: true)
        navigationItem.leftBarButtonItem = selectAllBarButton
        navigationItem.rightBarButtonItem = cancelBarButton
        
        let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setToolbarItems([forwardBarButton, flexibleSpaceBarButton, downloadBarButton, flexibleSpaceBarButton, importBarButton], animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        updateToolbarButtonsState()
    }
    
    @objc private func cancelSelectTapped() {
        if tableView.isEditing {
            title = AMLocalizedString("sharedItems", "Title of Shared Items section")
            tableView.setEditing(false, animated: true)
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = selectBarButton
            
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    @objc private func selectAllTapped() {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        if messagesArray.count == tableView.indexPathsForSelectedRows?.count {
            for row in 0..<numberOfRows {
                tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: false)
            }
        } else {
            for row in 0..<numberOfRows {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
            }
        }
        updateSelectCountTitle()
        updateToolbarButtonsState()
    }
    
    @objc private func forwardTapped() {
        guard let selectedMessages = selectedMessages() else {
            return
        }
        forwardMessages(selectedMessages)
    }
    
    @objc private func downloadTapped() {
        guard let selectedMessages = selectedMessages() else {
            return
        }
        
        var nodes = [MEGANode]()
        selectedMessages.forEach( { nodes.append($0.nodeList.node(at: 0)) } )
        
        downloadNodes(nodes)
    }
    
    @objc private func importTapped() {
        guard let selectedMessages = selectedMessages() else {
            return
        }
        
        var nodes = [MEGANode]()
        selectedMessages.forEach( { nodes.append($0.nodeList.node(at: 0)) } )
        
        importNodes(nodes)
    }
    
    // MARK: - Private methods

    private func selectedMessages() -> [MEGAChatMessage]? {
        guard let selectedMessagesIndexPaths = tableView.indexPathsForSelectedRows else {
            return nil
        }
        let selectedIndexes = selectedMessagesIndexPaths.map { $0.row }
        return selectedIndexes.map { messagesArray[$0] }
    }
    
    private func updateToolbarButtonsState() {
        if let selectedMessages = tableView.indexPathsForSelectedRows {
            toolbarItems?.forEach { $0.isEnabled = selectedMessages.count > 0 }
        } else {
            toolbarItems?.forEach { $0.isEnabled = false }
        }
    }
    
    private func updateSelectCountTitle() {
        guard let selectedCount = tableView.indexPathsForSelectedRows?.count else {
            title = AMLocalizedString("selectTitle", "Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos")
            return
        }
        if selectedCount == 1 {
            title = String(format: AMLocalizedString("oneItemSelected", "Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo") , selectedCount)
        } else {
            title = String(format: AMLocalizedString("itemsSelected", "Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo") , selectedCount)
        }
    }
    
    private func loadMoreFiles() {
        guard let source = MEGASdkManager.sharedMEGAChatSdk()?.loadAttachments(forChat: chatRoom.chatId, count: 16) else {
            return
        }
        
        switch source {
        case .error:
            MEGALogDebug("[ChatSharedFiles] Error fetching chat files because we are not logged in yet")
            
        case .none:
            MEGALogDebug("[ChatSharedFiles] No more files available")
            attachmentsLoaded = true
            activityIndicator.stopAnimating()
            
        case .local:
            MEGALogDebug("[ChatSharedFiles] Files will be fetched locally")
            attachmentsLoading = true
            
        case .remote:
            MEGALogDebug("[ChatSharedFiles] Files will be fetched remotely")
            attachmentsLoading = true
            
        @unknown default:
            MEGALogDebug("[ChatSharedFiles] Unnknown error")
        }
    }
    
    private func forwardMessages(_ messages: [MEGAChatMessage]) {
        let sendToNC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! UINavigationController
        let sendToVC = sendToNC.viewControllers.first as! SendToViewController
        sendToVC.sendMode = .forward
        sendToVC.messages = messages
        sendToVC.sourceChatId = chatRoom.chatId
        sendToVC.completion = { [weak self] chatIdNumbers, sentMessages in
            SVProgressHUD.showSuccess(withStatus: AMLocalizedString("messagesSent", "Success message shown after forwarding messages to other chats"))
            self?.cancelSelectTapped()
        }
        present(sendToNC, animated: true, completion: nil)
    }
    
    private func importNodes(_ nodes: [MEGANode]) {
        let browserNavigation = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
        present(browserNavigation, animated: true, completion: nil)
        let browserController = browserNavigation.viewControllers.first as! BrowserViewController
        browserController.selectedNodesArray = nodes
        browserController.browserAction = .import
        
        cancelSelectTapped()
    }
    
    private func downloadNodes(_ nodes: [MEGANode]) {
        guard let image = UIImage(named: "hudDownload") else {
            return
        }
        SVProgressHUD.show(image, status: AMLocalizedString("downloadStarted","Message shown when a download starts"))
        nodes.forEach { $0.mnz_downloadNodeOverwriting(false) }
        
        cancelSelectTapped()
    }
}

// MARK: - MEGAChatNodeHistoryDelegate.

extension ChatSharedItemsViewController: MEGAChatNodeHistoryDelegate {
    
    func onAttachmentLoaded(_ api: MEGAChatSdk, message: MEGAChatMessage?) {
        MEGALogDebug("[ChatSharedFiles] onAttachmentLoaded messageId: \(String(describing: message?.messageId)), node handle: \(String(describing: message?.nodeList.node(at: 0)?.handle)), node name: \(String(describing: message?.nodeList.node(at: 0)?.name))")
        
        guard let message = message else {
            attachmentsLoading = false
            activityIndicator.stopAnimating()
            return
        }
        
        if messagesArray.count == 0 {
            navigationItem.rightBarButtonItem = selectBarButton
        }
        
        tableView.mnz_performBatchUpdates({
            self.messagesArray.append(message)
                self.tableView.insertRows(at: [IndexPath(row: self.messagesArray.count - 1, section: 0)], with: .automatic)
        }) { _ in
            if self.tableView.isEmptyDataSetVisible {
                self.tableView.reloadEmptyDataSet()
            }
        }
    }
    
    func onAttachmentReceived(_ api: MEGAChatSdk, message: MEGAChatMessage) {
        MEGALogDebug("[ChatSharedFiles] onAttachmentReceived messageId: \(String(describing: message.messageId)), node handle: \(String(describing: message.nodeList.node(at: 0)?.handle)), node name: \(String(describing: message.nodeList.node(at: 0)?.name))")
        
        if messagesArray.count == 0 {
            navigationItem.rightBarButtonItem = selectBarButton
        }
    
        tableView.mnz_performBatchUpdates({
            self.messagesArray.insert(message, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }) { _ in
            if self.tableView.isEmptyDataSetVisible {
                self.tableView.reloadEmptyDataSet()
            }
        }
    }
    
    func onAttachmentDeleted(_ api: MEGAChatSdk, messageId: UInt64) {
        MEGALogDebug("[ChatSharedFiles] onAtonAttachmentReceivedtachmentLoaded \(messageId)")
        guard let message = messagesArray.first(where: {$0.messageId == messageId} ) else {
            return
        }
        
        guard let index = messagesArray.firstIndex(of: message) else {
            return
        }
        
        tableView.mnz_performBatchUpdates({
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.messagesArray.remove(at: index)
        }) { _ in
            if self.messagesArray.count == 0 {
                self.navigationItem.rightBarButtonItem = nil
                self.tableView.reloadEmptyDataSet()
            }
        }
    }
    
    func onTruncate(_ api: MEGAChatSdk, messageId: UInt64) {
        MEGALogDebug("[ChatSharedFiles] onTruncate")
        messagesArray.removeAll()
        tableView.reloadData()
        navigationItem.rightBarButtonItem = nil
    }
}

// MARK: - UITableViewDataSource

extension ChatSharedItemsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sharedItemCell", for: indexPath) as! ChatSharedItemTableViewCell
        
        let message = self.messagesArray[indexPath.row]
        let ownerName = MEGAStore.shareInstance().fetchUser(withUserHandle: message.userHandle).displayName
        
        cell.configure(for: message.nodeList.node(at: 0), owner: ownerName)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if !attachmentsLoaded && !attachmentsLoading  {
            let bottomView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60))
            activityIndicator.center = bottomView.center
            activityIndicator.startAnimating()
            activityIndicator.hidesWhenStopped = true
            bottomView.addSubview(activityIndicator)
            return bottomView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if !attachmentsLoaded && !attachmentsLoading  {
            loadMoreFiles()
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatSharedItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateSelectCountTitle()
            updateToolbarButtonsState()
        } else {
            guard let selectedNode = messagesArray[indexPath.row].nodeList.node(at: 0) else {
                return
            }
            
            if selectedNode.name.mnz_isImagePathExtension || selectedNode.name.mnz_isVideoPathExtension {
                let nodes = NSMutableArray()
                messagesArray.forEach { message in
                    guard let node = message.nodeList.node(at: 0) else {
                        return
                    }
                    if node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension {
                        if chatRoom.isPreview {
                            guard let authNode = MEGASdkManager.sharedMEGASdk().authorizeChatNode(node, cauth: chatRoom.authorizationToken) else { return }
                            nodes.add(authNode)
                        } else {
                            nodes.add(node)
                        }
                    }
                }
                
                guard let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes: nodes, api: MEGASdkManager.sharedMEGASdk(), displayMode: .chatSharedFiles, presenting: selectedNode, preferredIndex: 0) else { return }
                
                navigationController?.present(photoBrowserVC, animated: true, completion: nil)
            } else {
                if chatRoom.isPreview {
                    guard let authNode = MEGASdkManager.sharedMEGASdk().authorizeChatNode(selectedNode, cauth: chatRoom.authorizationToken) else { return }
                    authNode.mnz_open(in: navigationController, folderLink: false, fileLink: nil)
                } else {
                    selectedNode.mnz_open(in: navigationController, folderLink: false, fileLink: nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateSelectCountTitle()
            updateToolbarButtonsState()
        }
    }
}

// MARK: - DZNEmptyDataSetSource

extension ChatSharedItemsViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let attributes = Helper.titleAttributesForEmptyState() as? [NSAttributedString.Key : Any]
        if (MEGAReachabilityManager.isReachable()) {
            return NSAttributedString(string: AMLocalizedString("No Shared Files","Title shown when there are no shared files"), attributes: attributes)
        } else {
            return NSAttributedString(string: AMLocalizedString("noInternetConnection", "No Internet Connection"), attributes: attributes)
        }
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        if (MEGAReachabilityManager.isReachable()) {
            return UIImage(named: "sharedFilesEmptyState")
        } else {
            return UIImage(named: "noInternetEmptyState")
        }
    }
}

// MARK: - NodeActionViewControllerDelegate

extension ChatSharedItemsViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .forward:
            guard let message = messagesArray.first(where: { $0.nodeList.node(at: 0)?.handle == node.handle } ) else {
                return
            }
            forwardMessages([message])
            
        case .saveToPhotos:
            node.mnz_saveToPhotos(withApi: MEGASdkManager.sharedMEGASdk())
            
        case .download:
            downloadNodes([node])
            
        case .import:
            importNodes([node])
            
        default: break
        }
    }
}
