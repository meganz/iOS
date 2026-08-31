import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo
import os
import Security

private let migrationLog = Logger(subsystem: "mega.ios.migration", category: "share")

extension ShareViewController {
    @objc func injectSDKRepoDependencies() {
        MEGASDKRepo.DependencyInjection.sharedSdk = .shared
    }

    @objc func logMigrationState() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "MEGA",
            kSecAttrAccount: "sessionV3",
            kSecReturnAttributes: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let agrp = (result as? [CFString: Any])?[kSecAttrAccessGroup] as? String ?? "-"
        let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.mega.ios")?
            .lastPathComponent ?? "unresolved"
        let firstRun = UserDefaults(suiteName: "group.mega.ios")?.string(forKey: "FirstRun") ?? "-"
        migrationLog.error("sessionV3 status=\(status, privacy: .public) agrp=\(agrp, privacy: .public) group=\(container, privacy: .public) firstRun=\(firstRun, privacy: .public)")
    }

    @objc func successSendToChatMessage(attachments: [ShareAttachment], receiverCount: Int) -> String {
        if attachments.count > 1 {
            let filesString = Strings.Localizable.General.Format.Count.file(attachments.count)
            return Strings.Localizable.Share.Message.SendToChat.withMultipleFiles(receiverCount)
                .replacingOccurrences(of: "[A]", with: filesString)
        } else {
            guard let attachment = attachments.first else { return "" }
            let attachmentName = attachment.name ?? ""
            return Strings.Localizable.Share.Message.SendToChat.withOneFile(receiverCount)
                .replacingOccurrences(of: "[A]", with: attachmentName)
        }
    }
    
    @objc func appDataForUploadFile(localPath: String) async -> String? {
        let metadataUseCase = MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        )
        
        return await metadataUseCase.formattedCoordinate(forFilePath: localPath)
    }
    
    @objc func cancellableTransfer(parentNode: MEGANode, localFileURL: URL?, appData: String, isFile: Bool) -> CancellableTransfer {
        let uploadOptions = UploadOptionsEntity(
            appData: appData,
            pitagTrigger: .shareFromApp,
            pitagTarget: parentNode.isInShare() ? .incomingShare : .cloudDrive
        )
        return CancellableTransfer(
            handle: MEGAInvalidHandle,
            parentHandle: parentNode.handle,
            localFileURL: localFileURL,
            isFile: isFile,
            type: .upload,
            uploadOptions: uploadOptions
        )
    }
    
    @objc func uploadOptions(
        appData: String,
        users: [MEGAUser],
        chats: [MEGAChatListItem]
    ) -> MEGAUploadOptions {
        let pitagResolverUseCase = PitagResolverUseCase()
        let pitagTarget = pitagResolverUseCase.resolvePitagTarget(forChats: chats.toChatListItemEntities(), users: users.toUserEntities())
        let options = UploadOptionsEntity(
            appData: appData,
            isSourceTemporary: true,
            pitagTrigger: .shareFromApp,
            isChatUpload: true,
            pitagTarget: pitagTarget
        )
        return options.toMEGAUploadOptions()
    }
}
