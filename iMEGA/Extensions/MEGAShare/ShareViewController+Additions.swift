import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo

extension ShareViewController {
    @objc func injectSDKRepoDependencies() {
        MEGASDKRepo.DependencyInjection.sharedSdk = .shared
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
