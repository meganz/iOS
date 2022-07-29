import UIKit

typealias CloudDriveContextMenuDelegate = DisplayMenuDelegate & QuickFolderActionsMenuDelegate & RubbishBinMenuDelegate & UploadAddMenuDelegate

protocol DisplayMenuDelegate: ContextActionSheetDelegate {
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool)
    func sortMenu(didSelect sortType: SortOrderType)
}

protocol QuickFolderActionsMenuDelegate: ContextActionSheetDelegate {
    func quickFolderActionsMenu(didSelect action: QuickFolderAction, needToRefreshMenu: Bool)
}

protocol RubbishBinMenuDelegate: AnyObject {
    func rubbishBinMenu(didSelect action: RubbishBinAction)
}

protocol UploadAddMenuDelegate: ContextActionSheetDelegate {
    func uploadAddMenu(didSelect action: UploadAddAction)
}

protocol ChatMenuDelegate: ContextActionSheetDelegate {
    func chatStatusMenu(didSelect action: ChatStatusAction)
    func chatDoNotDisturbMenu(didSelect option: DNDTurnOnOption)
    func chatDisableDoNotDisturb()
}

protocol QRMenuDelegate: ContextActionSheetDelegate {
    func qrMenu(didSelect action: MyQRAction)
}

protocol MeetingContextMenuDelegate: ContextActionSheetDelegate {
    func meetingContextMenu(didSelect action: MeetingAction)
}

protocol ContextActionSheetDelegate: AnyObject {
    // iOS 13 Action Sheet delegate functions
    func showActionSheet(with actions: [ContextActionSheetAction])
}

final class ContextMenuManager: NSObject {
    weak var displayMenuDelegate: DisplayMenuDelegate?
    weak var quickFolderActionsMenuDelegate: QuickFolderActionsMenuDelegate?
    weak var uploadAddMenuDelegate: UploadAddMenuDelegate?
    weak var rubbishBinMenuDelegate: RubbishBinMenuDelegate?
    weak var chatMenuDelegate: ChatMenuDelegate?
    weak var qrMenuDelegate: QRMenuDelegate?
    weak var meetingContextMenuDelegate: MeetingContextMenuDelegate?
    
    private let createContextMenuUC: CreateContextMenuUseCaseProtocol
    
    init(displayMenuDelegate: DisplayMenuDelegate? = nil,
         quickFolderActionsMenuDelegate: QuickFolderActionsMenuDelegate? = nil,
         uploadAddMenuDelegate: UploadAddMenuDelegate? = nil,
         rubbishBinMenuDelegate: RubbishBinMenuDelegate? = nil,
         chatMenuDelegate: ChatMenuDelegate? = nil,
         qrMenuDelegate: QRMenuDelegate? = nil,
         meetingContextMenuDelegate: MeetingContextMenuDelegate? = nil,
         createContextMenuUseCase: CreateContextMenuUseCaseProtocol) {
        self.displayMenuDelegate = displayMenuDelegate
        self.quickFolderActionsMenuDelegate = quickFolderActionsMenuDelegate
        self.uploadAddMenuDelegate = uploadAddMenuDelegate
        self.rubbishBinMenuDelegate = rubbishBinMenuDelegate
        self.chatMenuDelegate = chatMenuDelegate
        self.qrMenuDelegate = qrMenuDelegate
        self.meetingContextMenuDelegate = meetingContextMenuDelegate
        self.createContextMenuUC = createContextMenuUseCase
    }
    
    // MARK: - Configure functions
    
    /// Defines the Context Type depending on whether the identifier passed as a parameter belongs to any action within the
    /// specified action types.
    ///
    ///  - Parameters:
    ///     - identifier: String that identify the action.
    ///  - Returns: The especific Context Type of the action with the identifier passed as a parameter.
    private func actionContextType(identifier: String) -> ContextMenuType {
        [
            (UploadAddAction.allValues, .uploadAdd),
            (DisplayAction.allValues, .display),
            (QuickFolderAction.allValues, .quickFolderActions),
            (SortOrderType.allValues, .sort),
            (RubbishBinAction.allValues, .rubbishBin),
            (ChatAction.allValues, .chat),
            (ChatStatusAction.allValues, .chatStatus),
            (DNDTurnOnOption.allValues, .chatDoNotDisturb),
            (DNDDisabledAction.allValues, .chatDoNotDisturb),
            (MyQRAction.allValues, .qr),
            (MeetingAction.allValues, .meeting)
        ]
            .compactMap {
                isTheIdentifier(identifier, partOf: $0, contextMenu: $1)
            }.first ?? .unknown
    }
    
    func isTheIdentifier(_ identifier: String, partOf array: [String], contextMenu: ContextMenuType) -> ContextMenuType? {
        array.contains(where: { $0 == identifier}) ? contextMenu : nil
    }
    
    /// Defines the action handler that executes the different delegate's functions depending on the context type of the selected action.
    ///
    ///  - Parameters:
    ///     - identifier: String that identify the action.
    ///     - contextType: The action's context type
    ///     - subMenuActions: (iOS 13) Action's submenu, allows us to open a new ActionSheet controller with the submenu's actions.
    private func actionHandler(_ identifier: String, contextType: ContextMenuType, subMenuActions: [ContextActionSheetAction]? = nil) {
        switch contextType {
        case .uploadAdd:
            guard let action = UploadAddAction(rawValue: identifier) else { return }
            if #available(iOS 14.0, *) {
                uploadAddMenuDelegate?.uploadAddMenu(didSelect: action)
            } else {
                guard let subMenuActions = subMenuActions else {
                    uploadAddMenuDelegate?.uploadAddMenu(didSelect: action)
                    return
                }

                uploadAddMenuDelegate?.showActionSheet(with: subMenuActions)
            }
            
        case .display:
            guard let action = DisplayAction(rawValue: identifier) else { return }
            
            if #available(iOS 14.0, *) {
                displayMenuDelegate?.displayMenu(didSelect: action,
                                                 needToRefreshMenu: action.rawValue == DisplayAction.listView.rawValue ||
                                                                    action.rawValue == DisplayAction.thumbnailView.rawValue)
            } else {
                guard let subMenuActions = subMenuActions else {
                    displayMenuDelegate?.displayMenu(didSelect: action, needToRefreshMenu: false)
                    return
                }

                displayMenuDelegate?.showActionSheet(with: subMenuActions)
            }
        case .sort:
            guard let sortTypeSelected = SortOrderType(rawValue: identifier) else { return }
            displayMenuDelegate?.sortMenu(didSelect: sortTypeSelected)
            
        case .quickFolderActions:
            guard let action = QuickFolderAction(rawValue: identifier) else { return }
            
            if #available(iOS 14.0, *) {
                quickFolderActionsMenuDelegate?.quickFolderActionsMenu(didSelect: action,
                                                                       needToRefreshMenu: action.rawValue != QuickFolderAction.info.rawValue &&
                                                                                          action.rawValue != QuickFolderAction.download.rawValue &&
                                                                                          action.rawValue != QuickFolderAction.rename.rawValue &&
                                                                                          action.rawValue != QuickFolderAction.copy.rawValue)
            } else {
                guard let subMenuActions = subMenuActions else {
                    quickFolderActionsMenuDelegate?.quickFolderActionsMenu(didSelect: action,
                                                                           needToRefreshMenu: false)
                    return
                }

                quickFolderActionsMenuDelegate?.showActionSheet(with: subMenuActions)
            }
            
        case .rubbishBin:
            guard let action = RubbishBinAction(rawValue: identifier) else { return }
            rubbishBinMenuDelegate?.rubbishBinMenu(didSelect: action)
            
        case .chat:
            if #unavailable(iOS 14.0) {
                guard let subMenuActions = subMenuActions else {
                    return
                }

                chatMenuDelegate?.showActionSheet(with: subMenuActions)
            }
            
        case .chatStatus:
            let currentStatus = MEGASdkManager.sharedMEGAChatSdk().onlineStatus()
            
            guard let action = ChatStatusAction(rawValue: identifier),
                  ChatStatus(rawValue: currentStatus.rawValue)?.identifier != action.rawValue else { return }
            
            chatMenuDelegate?.chatStatusMenu(didSelect: action)
            
        case .chatDoNotDisturb:
            guard let option = DNDTurnOnOption(rawValue: identifier) else {
                if let option = DNDDisabledAction(rawValue: identifier), option == .off {
                    chatMenuDelegate?.chatDisableDoNotDisturb()
                }
                
                return
            }
            
            chatMenuDelegate?.chatDoNotDisturbMenu(didSelect: option)
            
        case .qr:
            guard let action = MyQRAction(rawValue: identifier) else { return }
            
            qrMenuDelegate?.qrMenu(didSelect: action)
            
        case .meeting:
            guard let action = MeetingAction(rawValue: identifier) else { return }
            
            meetingContextMenuDelegate?.meetingContextMenu(didSelect: action)
            
        case .unknown:
            break
        }
    }
    
    // MARK: - iOS 13 Context Menu conversion functions
    
    /// Converts an action entity to an ActionSheet action
    ///
    ///  - Parameters:
    ///     - action: represent the context menu action entity that contains the information related to an action
    ///  - Returns: ActionSheet action, to configure the ActionSheetController (iOS 13)
    private func convertToAction(action: CMActionEntity) -> ContextActionSheetAction {
        ContextActionSheetAction(title: action.title,
                                 detail: action.detail,
                                 image: action.image,
                                 identifier: action.identifier,
                                 actionHandler: { [weak self] actionSheet in
            guard let `self` = self, let actionSheetIdentifier = actionSheet.identifier else { return }
            self.actionHandler(actionSheetIdentifier,
                               contextType: self.actionContextType(identifier: actionSheetIdentifier))
        })
    }
    
    /// Converts a menu entity within another menu, to an ActionSheet action. This type of conversion is needed whether the current context menu entity is a representable menu entity (has title, image, etc.)
    ///
    ///  - Parameters:
    ///     - menu: represent a context menu entity that contains the information related to this menu
    ///  - Returns: ActionSheet action, to configure the ActionSheetController (iOS 13)
    private func convertToAction(menu: CMEntity) -> ContextActionSheetAction {
        ContextActionSheetAction(title: menu.title,
                                 detail: menu.detail,
                                 image: menu.image,
                                 identifier: menu.identifier,
                                 actionHandler: { [weak self] actionSheet in
                guard let `self` = self, let actionSheetIdentifier = actionSheet.identifier else { return }
            self.actionHandler(actionSheetIdentifier,
                               contextType: self.actionContextType(identifier: actionSheetIdentifier),
                               subMenuActions: self.convertMenuToActions(menu: menu))
        })
    }
    
    /// Converts a menu entity to an array of ActionSheet actions.
    ///
    ///  - Parameters:
    ///     - menu: represent a context menu entity that contains the information related to this menu
    ///  - Returns: The ActionSheet actions array of the menu entity passed as a parameter
    func convertMenuToActions(menu: CMEntity) -> [ContextActionSheetAction] {
        menu.children.compactMap {
            if let action = $0 as? CMActionEntity {
                return [convertToAction(action: action)]
            } else if let menu = $0 as? CMEntity {
                if menu.title != nil {
                    return [convertToAction(menu: menu)]
                } else {
                    return convertMenuToActions(menu: menu)
                }
            } else {
                return nil
            }
        }.reduce([], +)
    }
    
    // MARK: - iOS14+ Context Menu conversion functions
    
    /// Converts the menu elements to items that can be part of UIMenu
    ///
    ///  - Parameters:
    ///     - items: Array of CMElement entities that can be CMEntity and CMActionEntity
    ///  - Returns: Array of UIMenuElements, available elements to create a UIMenu (iOS 14+)
    private func convertToMenuElements(items: [CMElement]) -> [UIMenuElement] {
        items.compactMap {
            if let action = $0 as? CMActionEntity {
                return UIAction(title: action.title ?? "",
                                image: action.image?.alpha(value: action.isEnabled ? 1.0 : 0.5),
                                identifier: UIAction.Identifier(rawValue: action.identifier ?? ""),
                                attributes: action.isEnabled ? [] : .disabled,
                                state: action.state == .on ? .on : .off) { [weak self] action in
                    guard let `self` = self else { return }
                    self.actionHandler(action.identifier.rawValue, contextType: self.actionContextType(identifier: action.identifier.rawValue))
                }
            } else if let menu = $0 as? CMEntity {
                return convertToMenu(menu: menu)
            } else {
                return nil
            }
        }
    }
    
    /// Converts a menu entity to a UIMenu.
    ///
    ///  - Parameters:
    ///     - menu: represent a context menu entity that contains the information related to this menu
    ///  - Returns: UIMenu that represent all actions and submenus of the current menu.
    private func convertToMenu(menu: CMEntity) -> UIMenu {
        if #available(iOS 15.0, *) {
            return UIMenu(title: menu.title ?? "",
                          subtitle: menu.detail ?? "",
                          image: menu.image,
                          options: menu.displayInline ? [.displayInline] : [],
                          children: convertToMenuElements(items: menu.children))
        } else {
            let menu =  UIMenu(title: menu.title ?? "",
                          image: menu.image,
                          options: menu.displayInline ? [.displayInline] : [],
                          children: convertToMenuElements(items: menu.children))
            return menu
        }
    }
    
    // MARK: - Create context menu with configurations
    
    /// Converts a menu entity to a UIMenu.
    ///
    ///  - Parameters:
    ///     - menu: represent a context menu entity that contains the information related to this menu
    ///  - Returns: UIMenu that represent all actions and submenus of the current menu.
    @available(iOS 14.0, *)
    func contextMenu(with configuration: CMConfigEntity) -> UIMenu? {
        guard let menuEntity = createContextMenuUC.createContextMenu(config: configuration) else { return nil }
        return convertToMenu(menu: menuEntity)
    }
    
    func actionSheetActions(with configuration: CMConfigEntity) -> [ContextActionSheetAction]? {
        guard let menuEntity = createContextMenuUC.createContextMenu(config: configuration) else { return nil }
        return convertMenuToActions(menu: menuEntity)
    }
}
