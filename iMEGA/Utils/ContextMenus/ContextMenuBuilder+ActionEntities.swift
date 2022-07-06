
extension ContextMenuBuilder {
    
    //MARK: - Upload Add Actions
    
    var choosePhotoVideo: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.choosePhotoVideo,
                       image: Asset.Images.NodeActions.saveToPhotos.image,
                       identifier: UploadAddAction.chooseFromPhotos.rawValue)
    }
    
    var capturePhotoVideo: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.capturePhotoVideo,
                       image: Asset.Images.ActionSheetIcons.capture.image,
                       identifier: UploadAddAction.capture.rawValue)
    }
    
    var importFromFiles: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.CloudDrive.Upload.importFromFiles,
                       image: Asset.Images.InfoActions.import.image,
                       identifier: UploadAddAction.importFrom.rawValue)
    }
    
    var newTextFile: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.newTextFile,
                       image: Asset.Images.NodeActions.textfile.image,
                       identifier: UploadAddAction.newTextFile.rawValue)
    }
    
    var scanDocument: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.scanDocument,
                       image: Asset.Images.ActionSheetIcons.scanDocument.image,
                       identifier: UploadAddAction.scanDocument.rawValue)
    }
    
    var newFolder: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.newFolder,
                       image: Asset.Images.ActionSheetIcons.newFolder.image,
                       identifier: UploadAddAction.newFolder.rawValue)
    }
    
    //MARK: - Display Actions
    
    var select: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.select,
                       image: Asset.Images.ActionSheetIcons.select.image,
                       identifier: DisplayAction.select.rawValue)
    }
    
    var thumbnailView: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.thumbnailView,
                       image: Asset.Images.ActionSheetIcons.thumbnailsThin.image,
                       identifier: DisplayAction.thumbnailView.rawValue,
                       state: currentViewMode() == .thumbnail ? .on : .off)
    }
    
    var listView: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.listView,
                       image: Asset.Images.ActionSheetIcons.gridThin.image,
                       identifier: DisplayAction.listView.rawValue,
                       state: currentViewMode() == .list ? .on : .off)
    }
    
    var emptyRubbishBin: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.emptyRubbishBin,
                       image: Asset.Images.NodeActions.rubbishBin.image,
                       identifier: DisplayAction.clearRubbishBin.rawValue)
    }
    
    var mediaDiscovery: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title,
                       image: Asset.Images.ActionSheetIcons.mediaDiscovery.image,
                       identifier: DisplayAction.mediaDiscovery.rawValue)
    }
    
    //MARK: - Sort Actions
    
    var sortNameAscending: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.nameAscending,
                       image: Asset.Images.ActionSheetIcons.SortBy.ascending.image,
                       identifier: SortOrderType.nameAscending.rawValue,
                       state: currentSortType() == .nameAscending ? .on : .off)
    }
    
    var sortNameDescending: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.nameDescending,
                       image: Asset.Images.ActionSheetIcons.SortBy.descending.image,
                       identifier: SortOrderType.nameDescending.rawValue,
                       state: currentSortType() == .nameDescending ? .on : .off)
    }
    
    var sortLargest: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.largest,
                       image: Asset.Images.ActionSheetIcons.SortBy.largest.image,
                       identifier: SortOrderType.largest.rawValue,
                       state: currentSortType() == .largest ? .on : .off)
    }
    
    var sortSmallest: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.smallest,
                       image: Asset.Images.ActionSheetIcons.SortBy.smallest.image,
                       identifier: SortOrderType.smallest.rawValue,
                       state: currentSortType() == .smallest ? .on : .off)
    }
    
    var sortNewest: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.newest,
                       image: Asset.Images.ActionSheetIcons.SortBy.newest.image,
                       identifier: SortOrderType.newest.rawValue,
                       state: currentSortType() == .newest ? .on : .off)
    }
    
    var sortOldest: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.oldest,
                       image: Asset.Images.ActionSheetIcons.SortBy.oldest.image,
                       identifier: SortOrderType.oldest.rawValue,
                       state: currentSortType() == .oldest ? .on : .off)
    }
    
    var sortLabel: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.CloudDrive.Sort.label,
                       image: Asset.Images.ActionSheetIcons.SortBy.sortLabel.image,
                       identifier: SortOrderType.label.rawValue,
                       state: currentSortType() == .label ? .on : .off)
    }
    
    var sortFavourite: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.favourite,
                       image: Asset.Images.ActionSheetIcons.SortBy.sortFavourite.image,
                       identifier: SortOrderType.favourite.rawValue,
                       state: currentSortType() == .favourite ? .on : .off)
    }
    
    //MARK: - Quick Folder Actions
    
    var info: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.info,
                       image: Asset.Images.Generic.info.image,
                       identifier: QuickFolderAction.info.rawValue)
    }
    
    var download: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.General.downloadToOffline,
                       image: Asset.Images.NodeActions.offline.image,
                       identifier: QuickFolderAction.download.rawValue)
    }
    
    var shareLink: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.CloudDrive.NodeOptions.shareLink,
                       image: Asset.Images.Generic.link.image,
                       identifier: QuickFolderAction.shareLink.rawValue)
    }
    
    var manageLink: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.CloudDrive.NodeOptions.manageLink,
                       image: Asset.Images.Generic.link.image,
                       identifier: QuickFolderAction.manageLink.rawValue)
    }
    
    var removeLink: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.General.MenuAction.RemoveLink.title(1),
                       image: Asset.Images.NodeActions.removeLink.image,
                       identifier: QuickFolderAction.removeLink.rawValue)
    }
    
    var leaveSharing: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.leaveFolder,
                       image: Asset.Images.NodeActions.leaveShare.image,
                       identifier: QuickFolderAction.leaveSharing.rawValue)
    }
    
    var removeSharing: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.removeSharing,
                       image: Asset.Images.SharedItems.removeShare.image,
                       identifier: QuickFolderAction.removeSharing.rawValue)
    }
    
    var copy: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.copy,
                       image: Asset.Images.NodeActions.copy.image,
                       identifier: QuickFolderAction.copy.rawValue)
    }
    
    var shareFolder: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.shareFolder,
                       image: Asset.Images.NodeActions.shareFolder.image,
                       identifier: QuickFolderAction.shareFolder.rawValue)
    }
    
    var manageFolder: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.manageShare,
                       image: Asset.Images.NodeActions.shareFolder.image,
                       identifier: QuickFolderAction.manageFolder.rawValue)
    }
    
    var rename: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.rename,
                       image: Asset.Images.Generic.rename.image,
                       identifier: QuickFolderAction.rename.rawValue)
    }
    
    //MARK: - Rubbish Bin Actions
    
    var restore: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.restore,
                       image: Asset.Images.NodeActions.restore.image,
                       identifier: RubbishBinAction.restore.rawValue)
    }
    
    var versions: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.versions,
                       detail: String(currentVersionsCount()),
                       image: Asset.Images.Generic.versions.image,
                       identifier: RubbishBinAction.versions.rawValue)
    }
    
    var remove: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.remove,
                       image: Asset.Images.NodeActions.rubbishBin.image,
                       identifier: RubbishBinAction.remove.rawValue)
    }
    
    //MARK: - Chat Actions
    
    func chatStatus(_ status: ChatStatus) -> CMActionEntity {
        CMActionEntity(title: status.localizedIdentifier,
                       identifier: status.identifier,
                       state: currentChatStatus() == status ? .on : .off)
    }
    
    func doNotDisturb(option: DNDTurnOnOption) -> CMActionEntity {
        CMActionEntity(title: option.localizedTitle,
                       identifier: option.rawValue)
    }
    
    //MARK: - My QR Code Actions
    
    var share: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.General.share,
                       identifier: MyQRAction.share.rawValue)
    }
    
    var settings: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.settingsTitle,
                       identifier: MyQRAction.settings.rawValue)
    }
    
    var resetQR: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.resetQrCode,
                       identifier: MyQRAction.resetQR.rawValue)
    }
    
    //MARK: - Meeting
    
    var startMeeting: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting,
                       image: Asset.Images.Meetings.startMeeting.image,
                       identifier: MeetingAction.startMeeting.rawValue)
    }
    
    var joinMeeting: CMActionEntity {
        CMActionEntity(title: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting,
                       image: Asset.Images.Meetings.joinAMeeting.image,
                       identifier: MeetingAction.joinMeeting.rawValue)
    }
}
