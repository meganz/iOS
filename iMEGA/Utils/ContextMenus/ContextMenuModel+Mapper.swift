import MEGADomain

extension CMActionEntity {
    func toContextMenuModel() -> ContextMenuModel {
        ContextMenuModel(type: type,
                         state: state == .on,
                         isEnabled: isEnabled)
    }
}

extension CMEntity {
    func toContextMenuModel() -> ContextMenuModel {
        ContextMenuModel(type: type,
                         displayInline: displayInline,
                         children: toContextMenuModels(children),
                         currentChatStatus: currentChatStatus?.toChatStatus().localizedIdentifier,
                         currentSortType: currentSortType?.toSortOrderType().localizedString,
                         dndRemainingTime: dndRemainingTime)
                         
    }
    
    func toContextMenuModels(_ array: [CMElement]?) -> [ContextMenuModel]? {
        array?.compactMap {
            if let action = $0 as? CMActionEntity {
                return action.toContextMenuModel()
            } else if let menu = $0 as? CMEntity {
                return ContextMenuModel(type: type,
                                        displayInline: displayInline,
                                        children: toContextMenuModels(menu.children))
            }
            return nil
        }
    }
}

extension ContextMenuModel {
    func dataFor(type: CMElementTypeEntity) -> ContextMenuDataModel? {
        switch type {
        case .uploadAdd(let action):
            return dataForUploadAddAction(action: action)
        case .display(let action):
            return dataForDisplayAction(action: action)
        case .quickActions(let action):
            return dataForQuickAction(action: action)
        case .sort(let sortType):
            return dataForSortType(sortType: sortType)
        case .rubbishBin(let action):
            return dataForRubbishBinAction(action: action)
        case .meeting(let action):
            return dataForMeetingAction(action: action)
        case .chat(let action):
            return dataForChatAction(action: action)
        case .chatStatus(let action):
            return dataForChatStatusAction(action: action)
        case .chatDoNotDisturbEnabled(let option):
            return dataForChatDoNotDisturbEnabledAction(option: option)
        case .chatDoNotDisturbDisabled(let option):
            return dataForChatDoNotDisturbDisabledAction(option: option)
        case .qr(let action):
            return dataForQRAction(action: action)
        default:
            return nil
        }
    }

    private func dataForUploadAddAction(action: UploadAddActionEntity) -> ContextMenuDataModel {
        switch action {
        case .chooseFromPhotos:
            return ContextMenuDataModel(identifier: "chooseFromPhotos", title: Strings.Localizable.choosePhotoVideo, image: Asset.Images.NodeActions.saveToPhotos.image)
        case .capture:
            return ContextMenuDataModel(identifier: "capture", title: Strings.Localizable.capturePhotoVideo, image: Asset.Images.ActionSheetIcons.capture.image)
        case .importFrom:
            return ContextMenuDataModel(identifier: "importFrom", title: Strings.Localizable.CloudDrive.Upload.importFromFiles, image: Asset.Images.InfoActions.import.image)
        case .scanDocument:
            return ContextMenuDataModel(identifier: "scanDocument", title: Strings.Localizable.scanDocument, image: Asset.Images.ActionSheetIcons.scanDocument.image)
        case .newFolder:
            return ContextMenuDataModel(identifier: "newFolder", title: Strings.Localizable.newFolder, image: Asset.Images.ActionSheetIcons.newFolder.image)
        case .newTextFile:
            return ContextMenuDataModel(identifier: "newTextFile", title: Strings.Localizable.newTextFile, image: Asset.Images.NodeActions.textfile.image)
        }
    }

    private func dataForQuickAction(action: QuickActionEntity) -> ContextMenuDataModel {
        switch action {
        case .info:
            return ContextMenuDataModel(identifier: "info", title: Strings.Localizable.info, image: Asset.Images.Generic.info.image)
        case .download:
            return ContextMenuDataModel(identifier: "download", title: Strings.Localizable.General.downloadToOffline, image: Asset.Images.NodeActions.offline.image)
        case .shareLink:
            return ContextMenuDataModel(identifier: "shareLink", title: Strings.Localizable.General.MenuAction.ShareLink.title(1), image: Asset.Images.Generic.link.image)
        case .manageLink:
            return ContextMenuDataModel(identifier: "manageLink", title: Strings.Localizable.General.MenuAction.ManageLink.title(1), image: Asset.Images.Generic.link.image)
        case .removeLink:
            return ContextMenuDataModel(identifier: "removeLink", title: Strings.Localizable.General.MenuAction.RemoveLink.title(1), image: Asset.Images.NodeActions.removeLink.image)
        case .shareFolder:
            return ContextMenuDataModel(identifier: "shareFolder", title: Strings.Localizable.General.MenuAction.ShareFolder.title(1), image: Asset.Images.NodeActions.shareFolder.image)
        case .manageFolder:
            return ContextMenuDataModel(identifier: "manageFolder", title: Strings.Localizable.manageShare, image: Asset.Images.NodeActions.shareFolder.image)
        case .rename:
            return ContextMenuDataModel(identifier: "rename", title: Strings.Localizable.rename, image: Asset.Images.Generic.rename.image)
        case .copy:
            return ContextMenuDataModel(identifier: "copy", title: Strings.Localizable.copy, image: Asset.Images.NodeActions.copy.image)
        case .removeSharing:
            return ContextMenuDataModel(identifier: "removeSharing", title: Strings.Localizable.removeSharing, image: Asset.Images.SharedItems.removeShare.image)
        case .leaveSharing:
            return ContextMenuDataModel(identifier: "leaveSharing", title: Strings.Localizable.leaveFolder, image: Asset.Images.NodeActions.leaveShare.image)
        }
    }

    private func dataForDisplayAction(action: DisplayActionEntity) -> ContextMenuDataModel {
        switch action {
        case .select:
            return ContextMenuDataModel(identifier: "select", title: Strings.Localizable.select, image: Asset.Images.ActionSheetIcons.select.image)
        case .mediaDiscovery:
            return ContextMenuDataModel(identifier: "mediaDiscovery", title: Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title, image: Asset.Images.ActionSheetIcons.mediaDiscovery.image)
        case .thumbnailView:
            return ContextMenuDataModel(identifier: "thumbnailView", title: Strings.Localizable.thumbnailView, image: Asset.Images.ActionSheetIcons.thumbnailsThin.image)
        case .listView:
            return ContextMenuDataModel(identifier: "listView", title: Strings.Localizable.listView, image: Asset.Images.ActionSheetIcons.gridThin.image)
        case .sort:
            return ContextMenuDataModel(identifier: "sort", title: Strings.Localizable.sortTitle, subtitle: currentSortType, image: Asset.Images.ActionSheetIcons.sort.image)
        case .clearRubbishBin:
            return ContextMenuDataModel(identifier: "clearRubbishBin", title: Strings.Localizable.emptyRubbishBin, image: Asset.Images.NodeActions.rubbishBin.image)
        case .filter:
            return ContextMenuDataModel(identifier: "filter", title: Strings.Localizable.filter, image: Asset.Images.ActionSheetIcons.filter.image)
        }
    }

    private func dataForSortType(sortType: SortOrderEntity) -> ContextMenuDataModel? {
        switch sortType {
        case .defaultAsc:
            return ContextMenuDataModel(identifier: "defaultAsc", title: Strings.Localizable.nameAscending, image: Asset.Images.ActionSheetIcons.SortBy.ascending.image)
        case .defaultDesc:
            return ContextMenuDataModel(identifier: "defaultDesc", title: Strings.Localizable.nameDescending, image: Asset.Images.ActionSheetIcons.SortBy.descending.image)
        case .sizeDesc:
            return ContextMenuDataModel(identifier: "sizeDesc", title: Strings.Localizable.largest, image: Asset.Images.ActionSheetIcons.SortBy.largest.image)
        case .sizeAsc:
            return ContextMenuDataModel(identifier: "sizeAsc", title: Strings.Localizable.smallest, image: Asset.Images.ActionSheetIcons.SortBy.smallest.image)
        case .modificationDesc:
            return ContextMenuDataModel(identifier: "modificationDesc", title: Strings.Localizable.newest, image: Asset.Images.ActionSheetIcons.SortBy.newest.image)
        case .modificationAsc:
            return ContextMenuDataModel(identifier: "modificationAsc", title: Strings.Localizable.oldest, image: Asset.Images.ActionSheetIcons.SortBy.oldest.image)
        case .labelAsc:
            return ContextMenuDataModel(identifier: "labelAsc", title: Strings.Localizable.CloudDrive.Sort.label, image: Asset.Images.ActionSheetIcons.SortBy.sortLabel.image)
        case .favouriteAsc:
            return ContextMenuDataModel(identifier: "favouriteAsc", title: Strings.Localizable.favourite, image: Asset.Images.ActionSheetIcons.SortBy.sortFavourite.image)
        default:
            return nil
        }
    }

    private func dataForRubbishBinAction(action: RubbishBinActionEntity) -> ContextMenuDataModel {
        switch action {
        case .restore:
            return ContextMenuDataModel(identifier: "restore", title: Strings.Localizable.restore, image: Asset.Images.NodeActions.restore.image)
        case .info:
            return ContextMenuDataModel(identifier: "info", title: Strings.Localizable.info, image: Asset.Images.Generic.info.image)
        case .versions:
            return ContextMenuDataModel(identifier: "versions", title: Strings.Localizable.versions, image: Asset.Images.Generic.versions.image)
        case .remove:
            return ContextMenuDataModel(identifier: "remove", title: Strings.Localizable.remove, image: Asset.Images.NodeActions.rubbishBin.image)
        }
    }

    private func dataForMeetingAction(action: MeetingActionEntity) -> ContextMenuDataModel {
        switch action {
        case .startMeeting:
            return ContextMenuDataModel(identifier: "startMeeting", title: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting, image: Asset.Images.Meetings.startMeeting.image)
        case .joinMeeting:
            return ContextMenuDataModel(identifier: "joinMeeting", title: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting, image: Asset.Images.Meetings.joinAMeeting.image)
        case .scheduleMeeting:
            return ContextMenuDataModel(identifier: "scheduleMeeting", title: Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting, image: Asset.Images.Meetings.scheduleMeeting.image)
        }
    }

    private func dataForChatAction(action: ChatActionEntity) -> ContextMenuDataModel {
        switch action {
        case .status:
            return ContextMenuDataModel(identifier: "status", title: Strings.Localizable.status, subtitle: currentChatStatus)
        case .doNotDisturb:
            return ContextMenuDataModel(identifier: "doNotDisturb", title: Strings.Localizable.doNotDisturb, subtitle: dndRemainingTime)
        }
    }

    private func dataForChatStatusAction(action: ChatStatusEntity) -> ContextMenuDataModel {
        return ContextMenuDataModel(identifier: action.toChatStatus().identifier ?? "", title: action.toChatStatus().localizedIdentifier)
    }

    private func dataForChatDoNotDisturbEnabledAction(option: DNDTurnOnOptionEntity) -> ContextMenuDataModel {
        return ContextMenuDataModel(identifier: option.toDNDTurnOnOption().rawValue, title: option.toDNDTurnOnOption().localizedTitle)
    }
    
    private func dataForChatDoNotDisturbDisabledAction(option: DNDDisabledActionEntity) -> ContextMenuDataModel {
        switch option {
        case .off:
            return ContextMenuDataModel(identifier: "off", title: Strings.Localizable.off)
        }
    }

    private func dataForQRAction(action: MyQRActionEntity) -> ContextMenuDataModel {
        switch action {
        case .share:
            return ContextMenuDataModel(identifier: "share", title: Strings.Localizable.General.share)
        case .settings:
            return ContextMenuDataModel(identifier: "settings", title: Strings.Localizable.settingsTitle)
        case .resetQR:
            return ContextMenuDataModel(identifier: "resetQR", title: Strings.Localizable.resetQrCode)
        }
    }
}
