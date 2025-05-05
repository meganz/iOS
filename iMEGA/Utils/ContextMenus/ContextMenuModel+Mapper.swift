import MEGADomain
import MEGAL10n

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
                         currentChatStatus: currentChatStatus?.localizedIdentifier,
                         currentSortType: currentSortType?.toSortOrderType().localizedString,
                         dndRemainingTime: dndRemainingTime,
                         currentFilterType: currentFilterType?.toFilterType().localizedString)
                         
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
        case .filter(let filterType):
            return dataForFilterType(filterType: filterType)
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
        case .album(let action):
            return dataForAlbumAction(action: action)
        case .videoPlaylist(let action):
            return dataForVideoPlaylistAction(action: action)
        default:
            return nil
        }
    }

    private func dataForUploadAddAction(action: UploadAddActionEntity) -> ContextMenuDataModel {
        switch action {
        case .chooseFromPhotos:
            return ContextMenuDataModel(identifier: "chooseFromPhotos", title: Strings.Localizable.choosePhotoVideo, image: UIImage.saveToPhotos)
        case .capture:
            return ContextMenuDataModel(identifier: "capture", title: Strings.Localizable.capturePhotoVideo, image: UIImage.capture)
        case .importFrom:
            return ContextMenuDataModel(identifier: "importFrom", title: Strings.Localizable.CloudDrive.Upload.importFromFiles, image: UIImage.import)
        case .importFolderLink:
            return ContextMenuDataModel(identifier: "importFrom", title: Strings.Localizable.importToCloudDrive, image: UIImage.import)
        case .scanDocument:
            return ContextMenuDataModel(identifier: "scanDocument", title: Strings.Localizable.scanDocument, image: UIImage.scanDocument)
        case .newFolder:
            return ContextMenuDataModel(identifier: "newFolder", title: Strings.Localizable.newFolder, image: UIImage.newFolder)
        case .newTextFile:
            return ContextMenuDataModel(identifier: "newTextFile", title: Strings.Localizable.newTextFile, image: UIImage.textfile)
        }
    }

    private func dataForQuickAction(action: QuickActionEntity) -> ContextMenuDataModel {
        switch action {
        case .info:
            return ContextMenuDataModel(identifier: "info", title: Strings.Localizable.info, image: UIImage.info)
        case .download:
            return ContextMenuDataModel(identifier: "download", title: Strings.Localizable.General.downloadToOffline, image: UIImage.offline)
        case .shareLink:
            return ContextMenuDataModel(identifier: "shareLink", title: Strings.Localizable.General.MenuAction.ShareLink.title(1), image: UIImage.link)
        case .manageLink:
            return ContextMenuDataModel(identifier: "manageLink", title: Strings.Localizable.General.MenuAction.ManageLink.title(1), image: UIImage.link)
        case .removeLink:
            return ContextMenuDataModel(identifier: "removeLink", title: Strings.Localizable.General.MenuAction.RemoveLink.title(1), image: UIImage.removeLink)
        case .shareFolder:
            return ContextMenuDataModel(identifier: "shareFolder", title: Strings.Localizable.General.MenuAction.ShareFolder.title(1), image: UIImage.shareFolder)
        case .manageFolder:
            return ContextMenuDataModel(identifier: "manageFolder", title: Strings.Localizable.manageShare, image: UIImage.shareFolder)
        case .rename:
            return ContextMenuDataModel(identifier: "rename", title: Strings.Localizable.rename, image: UIImage.rename)
        case .copy:
            return ContextMenuDataModel(identifier: "copy", title: Strings.Localizable.copy, image: UIImage.copy)
        case .removeSharing:
            return ContextMenuDataModel(identifier: "removeSharing", title: Strings.Localizable.removeSharing, image: UIImage.removeShare)
        case .leaveSharing:
            return ContextMenuDataModel(identifier: "leaveSharing", title: Strings.Localizable.leaveFolder, image: UIImage.leaveShare)
        case .sendToChat:
            return ContextMenuDataModel(identifier: "sendToChat", title: Strings.Localizable.General.sendToChat, image: UIImage.sendToChat)
        case .saveToPhotos:
            return ContextMenuDataModel(identifier: "saveToPhotos", title: Strings.Localizable.saveToPhotos, image: UIImage.saveToPhotos)
        case .hide:
            return ContextMenuDataModel(identifier: "hide", title: Strings.Localizable.General.MenuAction.Hide.title, image: UIImage.eyeOff)
        case .unhide:
            return ContextMenuDataModel(identifier: "unhide", title: Strings.Localizable.General.MenuAction.Unhide.title, image: UIImage.eyeOn)
        case .settings:
            return ContextMenuDataModel(identifier: "settings", title: Strings.Localizable.settingsTitle, image: .iconSettings)
        case .dispute:
            return ContextMenuDataModel(identifier: "dispute", title: Strings.Localizable.disputeTakedown, image: UIImage.disputeTakedown)
        }
    }

    private func dataForDisplayAction(action: DisplayActionEntity) -> ContextMenuDataModel {
        switch action {
        case .select:
            return ContextMenuDataModel(identifier: "select", title: Strings.Localizable.select, image: UIImage.selectItem)
        case .mediaDiscovery:
            return ContextMenuDataModel(identifier: "mediaDiscovery", title: Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title, image: UIImage.mediaDiscovery)
        case .thumbnailView:
            return ContextMenuDataModel(identifier: "thumbnailView", title: Strings.Localizable.thumbnailView, image: UIImage.thumbnailsThin)
        case .listView:
            return ContextMenuDataModel(identifier: "listView", title: Strings.Localizable.listView, image: UIImage.gridThin)
        case .sort:
            return ContextMenuDataModel(identifier: "sort", title: Strings.Localizable.sortTitle, subtitle: currentSortType, image: UIImage.sort)
        case .clearRubbishBin:
            return ContextMenuDataModel(identifier: "clearRubbishBin", title: Strings.Localizable.emptyRubbishBin, image: UIImage.rubbishBin)
        case .filter:
            return ContextMenuDataModel(identifier: "filter", title: Strings.Localizable.filter, subtitle: currentFilterType, image: UIImage.filter)
        case .filterActive:
            return ContextMenuDataModel(identifier: "filterActive", title: Strings.Localizable.filter, subtitle: currentFilterType, image: UIImage.filterActive)
        case .newPlaylist:
            return ContextMenuDataModel(identifier: "newPlaylist", title: Strings.Localizable.Videos.Tab.Playlist.Content.newPlaylist, image: UIImage.navigationbarAdd)
        }
    }

    private func dataForSortType(sortType: SortOrderEntity) -> ContextMenuDataModel? {
        switch sortType {
        case .defaultAsc:
            return ContextMenuDataModel(identifier: "defaultAsc", title: Strings.Localizable.nameAscending, image: UIImage.ascending)
        case .defaultDesc:
            return ContextMenuDataModel(identifier: "defaultDesc", title: Strings.Localizable.nameDescending, image: UIImage.descending)
        case .sizeDesc:
            return ContextMenuDataModel(identifier: "sizeDesc", title: Strings.Localizable.largest, image: UIImage.largest)
        case .sizeAsc:
            return ContextMenuDataModel(identifier: "sizeAsc", title: Strings.Localizable.smallest, image: UIImage.smallest)
        case .modificationDesc:
            return ContextMenuDataModel(identifier: "modificationDesc", title: Strings.Localizable.newest, image: UIImage.newest)
        case .modificationAsc:
            return ContextMenuDataModel(identifier: "modificationAsc", title: Strings.Localizable.oldest, image: UIImage.oldest)
        case .labelAsc:
            return ContextMenuDataModel(identifier: "labelAsc", title: Strings.Localizable.CloudDrive.Sort.label, image: UIImage.sortLabel)
        case .favouriteAsc:
            return ContextMenuDataModel(identifier: "favouriteAsc", title: Strings.Localizable.favourite, image: UIImage.sortFavourite)
        default:
            return nil
        }
    }
    
    private func dataForFilterType(filterType: FilterEntity) -> ContextMenuDataModel? {
        switch filterType {
        case .allMedia:
            return ContextMenuDataModel(identifier: "allMedias", title: Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.allMedia)
        case .images:
            return ContextMenuDataModel(identifier: "images", title: Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.images)
        case .videos:
            return ContextMenuDataModel(identifier: "videos", title: Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.videos)
        default:
            return nil
        }
    }

    private func dataForRubbishBinAction(action: RubbishBinActionEntity) -> ContextMenuDataModel {
        switch action {
        case .restore:
            return ContextMenuDataModel(identifier: "restore", title: Strings.Localizable.restore, image: UIImage.restore)
        case .info:
            return ContextMenuDataModel(identifier: "info", title: Strings.Localizable.info, image: UIImage.info)
        case .versions:
            return ContextMenuDataModel(identifier: "versions", title: Strings.Localizable.versions, image: UIImage.versions)
        case .remove:
            return ContextMenuDataModel(identifier: "remove", title: Strings.Localizable.remove, image: UIImage.rubbishBin)
        }
    }

    private func dataForMeetingAction(action: MeetingActionEntity) -> ContextMenuDataModel {
        switch action {
        case .startMeeting:
            return ContextMenuDataModel(identifier: "startMeeting", title: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting, image: UIImage.startMeeting)
        case .joinMeeting:
            return ContextMenuDataModel(identifier: "joinMeeting", title: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting, image: UIImage.joinAMeeting)
        case .scheduleMeeting:
            return ContextMenuDataModel(identifier: "scheduleMeeting", title: Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting, image: UIImage.scheduleMeeting)
        }
    }

    private func dataForChatAction(action: ChatActionEntity) -> ContextMenuDataModel {
        switch action {
        case .status:
            return ContextMenuDataModel(identifier: "status", title: Strings.Localizable.status, subtitle: currentChatStatus)
        case .doNotDisturb:
            return ContextMenuDataModel(identifier: "doNotDisturb", title: Strings.Localizable.doNotDisturb, subtitle: dndRemainingTime)
        case .archivedChats:
            return ContextMenuDataModel(identifier: "archivedChats", title: Strings.Localizable.archivedChats)
        }
    }

    private func dataForChatStatusAction(action: ChatStatusEntity) -> ContextMenuDataModel {
        ContextMenuDataModel(identifier: action.identifier ?? "", title: action.localizedIdentifier)
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
        case .qrSettings:
            return ContextMenuDataModel(
                identifier: "qrSettings",
                title: Strings.Localizable.settingsTitle,
                image: .iconSettings
            )
        case .resetQR:
            return ContextMenuDataModel(identifier: "resetQR", title: Strings.Localizable.resetQrCode)
        }
    }
    
    private func dataForAlbumAction(action: AlbumActionEntity) -> ContextMenuDataModel {
        switch action {
        case .selectAlbumCover:
            return ContextMenuDataModel(identifier: "selectAlbumCover", title: Strings.Localizable.CameraUploads.Albums.selectAlbumCover, image: UIImage.selectAlbumCover)
        case .delete:
            return ContextMenuDataModel(identifier: "delete", title: Strings.Localizable.delete, image: UIImage.deleteAlbum)
        }
    }
    
    private func dataForVideoPlaylistAction(action: VideoPlaylistActionEntity) -> ContextMenuDataModel {
        switch action {
        case .addVideosToVideoPlaylistContent:
            ContextMenuDataModel(
                identifier: "addVideosToVideoPlaylist",
                title: Strings.Localizable.Videos.Tab.Playlist.PlaylistContent.Menu.addVideos,
                image: UIImage.navigationbarAdd
            )
        case .delete:
            ContextMenuDataModel(
                identifier: "deleteVideoPlaylist",
                title: Strings.Localizable.Videos.Tab.Playlist.PlaylistContent.Menu.deletePlaylist,
                image: UIImage.deleteVideoPlaylist
            )
        }
    }
}
