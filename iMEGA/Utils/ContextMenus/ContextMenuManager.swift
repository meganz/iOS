import MEGADomain
import SwiftUI
import UIKit

typealias CloudDriveContextMenuDelegate = DisplayMenuDelegate & QuickActionsMenuDelegate & RubbishBinMenuDelegate & UploadAddMenuDelegate

typealias FolderLinkContextMenuDelegate = DisplayMenuDelegate & QuickActionsMenuDelegate & UploadAddMenuDelegate & RubbishBinMenuDelegate

typealias FileLinkContextMenuDelegate = QuickActionsMenuDelegate & UploadAddMenuDelegate & RubbishBinMenuDelegate

protocol DisplayMenuDelegate: AnyObject {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool)
    func sortMenu(didSelect sortType: SortOrderType)
}

protocol QuickActionsMenuDelegate: AnyObject {
    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool)
}

protocol RubbishBinMenuDelegate: AnyObject {
    func rubbishBinMenu(didSelect action: RubbishBinActionEntity)
}

protocol UploadAddMenuDelegate: AnyObject {
    func uploadAddMenu(didSelect action: UploadAddActionEntity)
}

protocol ChatMenuDelegate: AnyObject {
    func chatStatusMenu(didSelect action: ChatStatusEntity)
    func chatDoNotDisturbMenu(didSelect option: DNDTurnOnOption)
    func chatDisableDoNotDisturb()
    func archivedChatsTapped()
}

protocol QRMenuDelegate: AnyObject {
    func qrMenu(didSelect action: MyQRActionEntity)
}

protocol MeetingContextMenuDelegate: AnyObject {
    func meetingContextMenu(didSelect action: MeetingActionEntity)
}

protocol FilterMenuDelegate: AnyObject {
    func filterMenu(didSelect filterType: FilterType)
}

protocol AlbumMenuDelegate: AnyObject {
    func albumMenu(didSelect action: AlbumActionEntity)
}

protocol VideoPlaylistMenuDelegate: AnyObject {
    func videoPlaylistMenu(didSelect action: VideoPlaylistActionEntity)
}

final class ContextMenuManager: NSObject {
    weak var displayMenuDelegate: (any DisplayMenuDelegate)?
    weak var quickActionsMenuDelegate: (any QuickActionsMenuDelegate)?
    weak var uploadAddMenuDelegate: (any UploadAddMenuDelegate)?
    weak var rubbishBinMenuDelegate: (any RubbishBinMenuDelegate)?
    weak var chatMenuDelegate: (any ChatMenuDelegate)?
    weak var qrMenuDelegate: (any QRMenuDelegate)?
    weak var meetingContextMenuDelegate: (any MeetingContextMenuDelegate)?
    weak var filterMenuDelegate: (any FilterMenuDelegate)?
    weak var albumMenuDelegate: (any AlbumMenuDelegate)?
    weak var videoPlaylistMenuDelegate: (any VideoPlaylistMenuDelegate)?
    
    private let createContextMenuUC: any CreateContextMenuUseCaseProtocol
    
    init(displayMenuDelegate: (any DisplayMenuDelegate)? = nil,
         quickActionsMenuDelegate: (any QuickActionsMenuDelegate)? = nil,
         uploadAddMenuDelegate: (any UploadAddMenuDelegate)? = nil,
         rubbishBinMenuDelegate: (any RubbishBinMenuDelegate)? = nil,
         chatMenuDelegate: (any ChatMenuDelegate)? = nil,
         qrMenuDelegate: (any QRMenuDelegate)? = nil,
         meetingContextMenuDelegate: (any MeetingContextMenuDelegate)? = nil,
         filterMenuDelegate: (any FilterMenuDelegate)? = nil,
         createContextMenuUseCase: any CreateContextMenuUseCaseProtocol,
         albumMenuDelegate: (any AlbumMenuDelegate)? = nil,
         videoPlaylistMenuDelegate: (any VideoPlaylistMenuDelegate)? = nil
    ) {
        self.displayMenuDelegate = displayMenuDelegate
        self.quickActionsMenuDelegate = quickActionsMenuDelegate
        self.uploadAddMenuDelegate = uploadAddMenuDelegate
        self.rubbishBinMenuDelegate = rubbishBinMenuDelegate
        self.chatMenuDelegate = chatMenuDelegate
        self.qrMenuDelegate = qrMenuDelegate
        self.meetingContextMenuDelegate = meetingContextMenuDelegate
        self.filterMenuDelegate = filterMenuDelegate
        self.createContextMenuUC = createContextMenuUseCase
        self.albumMenuDelegate = albumMenuDelegate
        self.videoPlaylistMenuDelegate = videoPlaylistMenuDelegate
    }
    
    // MARK: - Configure functions
    
    /// Defines the action handler that executes the different delegate's functions depending on the context type of the selected action.
    ///
    ///  - Parameters:
    ///     - identifier: String that identify the action.
    ///     - contextType: The action's context type
    ///     - subMenuActions: (iOS 13) Action's submenu, allows us to open a new ActionSheet controller with the submenu's actions.
    private func actionHandler(_ identifier: String, contextType: CMElementTypeEntity, subMenuActions: [ContextActionSheetAction]? = nil) {
        CrashlyticsLogger.log(category: .cloudDrive, "contextMenu identifier: \(identifier), type: \(contextType)")
        
        switch contextType {
        case .uploadAdd(let action):
            uploadAddMenuDelegate?.uploadAddMenu(didSelect: action)
            
        case .display(let action):
            displayMenuDelegate?.displayMenu(didSelect: action,
                                             needToRefreshMenu: [.listView, .thumbnailView, .mediaDiscovery].contains(action))
        case .sort(let option):
            displayMenuDelegate?.sortMenu(didSelect: option.toSortOrderType())
            
        case .filter(let entity):
            filterMenuDelegate?.filterMenu(didSelect: entity.toFilterType())
            
        case .quickActions(let action):
            quickActionsMenuDelegate?.quickActionsMenu(didSelect: action,
                                                       needToRefreshMenu: action != .info &&
                                                       action != .download &&
                                                       action != .rename &&
                                                       action != .copy)
            
        case .rubbishBin(let action):
            rubbishBinMenuDelegate?.rubbishBinMenu(didSelect: action)
            
        case .chatStatus(let action):
            let currentStatus =  MEGAChatSdk.shared.onlineStatus()
            guard currentStatus.toChatStatusEntity() != action else { return }
            
            chatMenuDelegate?.chatStatusMenu(didSelect: action)
            
        case .chatDoNotDisturbEnabled(let option):
            chatMenuDelegate?.chatDoNotDisturbMenu(didSelect: option.toDNDTurnOnOption())
            
        case .chatDoNotDisturbDisabled:
            chatMenuDelegate?.chatDisableDoNotDisturb()
            
        case .qr(let action):
            qrMenuDelegate?.qrMenu(didSelect: action)
            
        case .meeting(let action):
            meetingContextMenuDelegate?.meetingContextMenu(didSelect: action)
            
        case .album(let action):
            albumMenuDelegate?.albumMenu(didSelect: action)
            
        case .chat(let action):
            if action == .archivedChats {
                chatMenuDelegate?.archivedChatsTapped()
            }
        case .videoPlaylist(let action):
            videoPlaylistMenuDelegate?.videoPlaylistMenu(didSelect: action)
            
        default:
            break
        }
    }
    
    // MARK: - iOS 13 Context Menu conversion functions
    
    /// Converts an action entity to an ActionSheet action
    ///
    ///  - Parameters:
    ///     - action: Represent the context menu action entity that contains the information related to an action
    ///  - Returns: ActionSheet action, to configure the ActionSheetController (iOS 13)
    private func convertToAction(action: CMActionEntity) -> ContextActionSheetAction {
        var actionModel = action.toContextMenuModel()
        return ContextActionSheetAction(title: actionModel.data?.title,
                                        detail: actionModel.data?.subtitle,
                                        image: actionModel.data?.image,
                                        identifier: actionModel.data?.identifier,
                                        type: actionModel.type,
                                        actionHandler: { [weak self] actionSheet in
            guard let self, let actionSheetIdentifier = actionSheet.identifier  else { return }
            self.actionHandler(actionSheetIdentifier,
                               contextType: action.type)
        })
    }
    
    /// Converts a menu entity within another menu, to an ActionSheet action. This type of conversion is needed whether the current context menu entity is a representable menu entity (has title, image, etc.)
    ///
    ///  - Parameters:
    ///     - menu: Represent a context menu entity that contains the information related to this menu
    ///  - Returns: ActionSheet action, to configure the ActionSheetController (iOS 13)
    private func convertToAction(menu: CMEntity) -> ContextActionSheetAction {
        var menuModel = menu.toContextMenuModel()
        return ContextActionSheetAction(title: menuModel.data?.title,
                                        detail: menuModel.data?.subtitle,
                                        image: menuModel.data?.image,
                                        identifier: menuModel.data?.identifier,
                                        type: menuModel.type,
                                        actionHandler: { [weak self] actionSheet in
                guard let `self` = self, let actionSheetIdentifier = actionSheet.identifier  else { return }
            self.actionHandler(actionSheetIdentifier,
                               contextType: menuModel.type,
                               subMenuActions: self.convertMenuToActions(menu: menu))
        })
    }
    
    /// Converts a menu entity to an array of ActionSheet actions.
    ///
    ///  - Parameters:
    ///     - menu: Represent a context menu entity that contains the information related to this menu
    ///  - Returns: The ActionSheet actions array of the menu entity passed as a parameter
    func convertMenuToActions(menu: CMEntity) -> [ContextActionSheetAction] {
        menu.children.compactMap {
            if let action = $0 as? CMActionEntity {
                return [convertToAction(action: action)]
            } else if let menu = $0 as? CMEntity {
                var menuModel = menu.toContextMenuModel()
                if menuModel.data?.title != nil {
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
    ///  - Returns: Array of UIMenuElements, available elements to create a UIMenu
    private func convertToMenuElements(items: [CMElement]) -> [UIMenuElement] {
        items.compactMap {
            if let action = ($0 as? CMActionEntity) {
                var actionModel = action.toContextMenuModel()
                return UIAction(title: actionModel.data?.title ?? "",
                                image: actionModel.data?.image?.alpha(value: action.isEnabled ? 1.0 : 0.5),
                                identifier: UIAction.Identifier(rawValue: actionModel.data?.identifier ?? ""),
                                attributes: actionModel.isEnabled ? [] : .disabled,
                                state: actionModel.state ? .on : .off) { [weak self] action in
                    guard let `self` = self  else { return }
                    self.actionHandler(action.identifier.rawValue, contextType: actionModel.type)
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
    ///     - menu: Represent a context menu entity that contains the information related to this menu
    ///  - Returns: UIMenu that represent all actions and submenus of the current menu.
    private func convertToMenu(menu: CMEntity) -> UIMenu {
        var menuModel = menu.toContextMenuModel()
        let menuItem = UIMenu(title: menuModel.data?.title ?? "",
                              subtitle: menuModel.data?.subtitle ?? "",
                              image: menuModel.data?.image,
                              options: menuModel.displayInline ? [.displayInline] : [],
                              children: convertToMenuElements(items: menu.children))
        return menuItem
    }
    
    // MARK: - Create context menu with configurations
    
    /// Converts a menu entity to a UIMenu.
    ///
    ///  - Parameters:
    ///     - menu: Represent a context menu entity that contains the information related to this menu
    ///  - Returns: UIMenu that represent all actions and submenus of the current menu.
    func contextMenu(with configuration: CMConfigEntity) -> UIMenu? {
        guard let menuEntity = createContextMenuUC.createContextMenu(config: configuration) else { return nil }
        return convertToMenu(menu: menuEntity)
    }
    
    func actionSheetActions(with configuration: CMConfigEntity) -> [ContextActionSheetAction]? {
        guard let menuEntity = createContextMenuUC.createContextMenu(config: configuration) else { return nil }
        return convertMenuToActions(menu: menuEntity)
    }

    func menu<Label: View>(with configuration: CMConfigEntity, @ViewBuilder label: @escaping () -> Label) -> ContextMenuWithButtonView<Label>? {
        guard let menuEntity = createContextMenuUC.createContextMenu(config: configuration) else { return nil }
        return ContextMenuWithButtonView(
            menu: menuEntity, label: label
        ) { [weak self] identifier, contextType in
            guard let self else { return }
            actionHandler(identifier, contextType: contextType)
        }
    }
}
