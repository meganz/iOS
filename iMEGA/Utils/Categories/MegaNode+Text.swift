//
//  MegaNode+Text.swift
//  MEGA
//
//  Created by Meler Paine on 2023/3/16.
//  Copyright © 2023 MEGA. All rights reserved.
//

import MEGADomain

extension MEGANode {
    
    @objc func readTextBasedFileContent(completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let offlineNodeExist = MEGAStore.shareInstance().offlineNode(with: self)
            
            var previewDocumentPath = ""
            if offlineNodeExist != nil {
                previewDocumentPath = Helper.pathForOffline().append(pathComponent: offlineNodeExist?.localPath ?? "")
            } else {
                let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: self.base64Handle ?? "")
                let tmpFilePath = nodeFolderPath.append(pathComponent: self.name ?? "")
                if FileManager.default.fileExists(atPath: tmpFilePath) {
                    previewDocumentPath = tmpFilePath
                }
            }
            
            if !previewDocumentPath.isEmpty {
                if let content = try? String(contentsOf: URL(fileURLWithPath: previewDocumentPath), encoding: .utf8) {
                    completion(content)
                } else if let content = try? String(contentsOf: URL(fileURLWithPath: previewDocumentPath), encoding: .ascii) {
                    completion(content)
                } else {
                    completion(nil)
                    return
                }
                return
            }
            
            let sdk = MEGASdkManager.sharedMEGASdk()
            let nodeRepository = NodeRepository.newRepo
            let fileSystemRepository = FileSystemRepository(fileManager: FileManager.default)
            let nodeEntity = self.toNodeEntity()
            let nodeHandle = nodeEntity.handle
            let downloadNodeUseCase = DownloadNodeUseCase(
                downloadFileRepository: DownloadFileRepository(sdk: sdk),
                offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: sdk),
                fileSystemRepository: fileSystemRepository,
                nodeRepository: nodeRepository,
                nodeDataRepository: NodeDataRepository.newRepo,
                fileCacheRepository: FileCacheRepository.newRepo,
                mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
                preferenceRepository: PreferenceRepository.newRepo)
            downloadNodeUseCase.downloadFileToTempFolder(nodeHandle: nodeHandle, appData: nil) { (transferEntity) in
                let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
                print("download text file percentage: \(percentage)")
            } completion: { (result: Result<TransferEntity, TransferErrorEntity>) in
                switch result {
                case .failure(_):
                    completion(nil)
                case .success(let transferEntity):
                    guard let path = transferEntity.path else { return }
                    do {
                        var encode: String.Encoding = .utf8
                        let content = try String(contentsOfFile: path, usedEncoding: &encode)
                        completion(content)
                    } catch {
                        completion(nil)
                    }
                }
            }
        }
    }
    
}
