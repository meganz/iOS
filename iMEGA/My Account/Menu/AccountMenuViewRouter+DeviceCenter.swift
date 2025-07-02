import DeviceCenter
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

extension AccountMenuViewRouter {
    private struct DeviceCenterActionIconAssets {
        static let cameraUploadsSettings = "cameraUploadsSettings"
        static let info = "info"
        static let rename = "rename"
        static let cloudDriveFolder = "cloudDriveFolder"
        static let sort = "sort"
        static let ascending = "ascending"
        static let descending = "descending"
        static let largest = "largest"
        static let smallest = "smallest"
        static let newest = "newest"
        static let oldest = "oldest"
        static let label = "label"
        static let favourite = "favourite"
    }

    func showDeviceCentre() {
        DeviceListViewRouter(
            navigationController: navigationController,
            deviceCenterBridge: makeDeviceCenterBridge(),
            deviceCenterUseCase:
                DeviceCenterUseCase(
                    deviceCenterRepository:
                        DeviceCenterRepository.newRepo
                ),
            nodeUseCase:
                NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                ),
            cameraUploadsUseCase:
                CameraUploadsUseCase(
                    cameraUploadsRepository: CameraUploadsRepository.newRepo
                ),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationCenter: NotificationCenter.default,
            deviceCenterActions: makeDeviceCenterActionList()
        ).start()
    }

    private func makeDeviceCenterBridge() -> DeviceCenterBridge {
        let deviceCenterBridge = DeviceCenterBridge()
        deviceCenterBridge.cameraUploadActionTapped = { cameraUploadStatusChanged in
            didTapCameraUploadsAction(statusChanged: cameraUploadStatusChanged)
        }

        deviceCenterBridge.renameActionTapped = { renameEntity in
            didTapRenameAction(renameEntity)
        }

        deviceCenterBridge.infoActionTapped = { resourceInfoModel in
            didTapInfoAction(resourceInfoModel)
        }

        deviceCenterBridge.showInTapped = { showInActionEntity in
            didTapNavigateToContent(showInActionEntity)
        }

        return deviceCenterBridge
    }

    private func makeDeviceCenterActionList() -> [ContextAction] {
        [
            ContextAction(
                type: .cameraUploads,
                title: Strings.Localizable.General.cameraUploads,
                dynamicSubtitle: {
                    CameraUploadManager.isCameraUploadEnabled ? Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.enabled :
                    Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.disabled
                },
                icon: DeviceCenterActionIconAssets.cameraUploadsSettings
            ),
            ContextAction(
                type: .info,
                title: Strings.Localizable.info,
                icon: DeviceCenterActionIconAssets.info
            ),
            ContextAction(
                type: .rename,
                title: Strings.Localizable.rename,
                icon: DeviceCenterActionIconAssets.rename
            ),
            ContextAction(
                type: .sort,
                title: Strings.Localizable.sortTitle,
                icon: DeviceCenterActionIconAssets.sort,
                subActions: [
                    ContextAction(
                        type: .sortAscending,
                        title: Strings.Localizable.nameAscending,
                        icon: DeviceCenterActionIconAssets.ascending
                    ),
                    ContextAction(
                        type: .sortDescending,
                        title: Strings.Localizable.nameDescending,
                        icon: DeviceCenterActionIconAssets.descending
                    ),
                    ContextAction(
                        type: .sortLargest,
                        title: Strings.Localizable.largest,
                        icon: DeviceCenterActionIconAssets.largest
                    ),
                    ContextAction(
                        type: .sortSmallest,
                        title: Strings.Localizable.smallest,
                        icon: DeviceCenterActionIconAssets.smallest
                    ),
                    ContextAction(
                        type: .sortNewest,
                        title: Strings.Localizable.newest,
                        icon: DeviceCenterActionIconAssets.newest
                    ),
                    ContextAction(
                        type: .sortOldest,
                        title: Strings.Localizable.oldest,
                        icon: DeviceCenterActionIconAssets.oldest
                    ),
                    ContextAction(
                        type: .sortLabel,
                        title: Strings.Localizable.CloudDrive.Sort.label,
                        icon: DeviceCenterActionIconAssets.label
                    ),
                    ContextAction(
                        type: .sortFavourite,
                        title: Strings.Localizable.favourite,
                        icon: DeviceCenterActionIconAssets.favourite
                    )
                ]
            )
        ]
    }

    private func didTapCameraUploadsAction(
        statusChanged: @escaping () -> Void
    ) {
        CameraUploadsSettingsViewRouter(
            presenter: navigationController,
            closure: {
                statusChanged()
            }).start()
    }

    private func didTapRenameAction(
        _ renameEntity: RenameActionEntity
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            RenameRouter(
                presenter: navigationController,
                renameEntity: renameEntity,
                renameUseCase: RenameUseCase(
                    renameRepository: RenameRepository.newRepo
                )
            ).start()
        }
    }

    private func didTapInfoAction(
        _ infoModel: ResourceInfoModel
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ResourceInfoViewRouter(
                presenter: navigationController,
                infoModel: infoModel
            ).start()
        }
    }

    private func didTapNavigateToContent(_ navigateToContentEntity: NavigateToContentActionEntity) {
        switch navigateToContentEntity.type {
        case .showInCloudDrive:
            didTapShowInCloudDriveAction(
                navigateToContentEntity.node,
                warningMessage: navigateToContentEntity.error
            )
        case .showInBackups:
            didTapShowInBackupsAction(
                navigateToContentEntity.node,
                warningMessage: navigateToContentEntity.error
            )
        default: break
        }
    }

    private func didTapShowInCloudDriveAction(
        _ node: NodeEntity,
        warningMessage: String?
    ) {
        pushCDViewController(
            node,
            isBackup: false,
            warningMessage: warningMessage
        )
    }

    private func didTapShowInBackupsAction(
        _ node: NodeEntity,
        warningMessage: String?
    ) {
        pushCDViewController(
            node,
            isBackup: true,
            warningMessage: warningMessage
        )
    }

    private func pushCDViewController(
        _ node: NodeEntity,
        isBackup: Bool,
        warningMessage: String? = nil
    ) {
        guard let viewController = createCloudDriveVCForNode(
            node,
            isBackup: isBackup,
            warningMessage: warningMessage
        ) else { return }

        navigationController.pushViewController(viewController, animated: true)
    }

    private func createCloudDriveVCForNode(
        _ node: NodeEntity,
        isBackup: Bool,
        warningMessage: String?
    ) -> UIViewController? {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)

        let warningViewModel =
        warningMessage != nil ?
        WarningBannerViewModel(warningType: .backupStatusError(warningMessage ?? "")): nil

        return factory.buildBare(
            parentNode: node,
            config: .init(
                displayMode: isBackup ? .backup : .cloudDrive,
                warningViewModel: warningViewModel
            )
        )
    }
}
