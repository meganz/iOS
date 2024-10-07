import FirebaseCrashlytics
import Foundation
import MEGADomain
import Photos

@objc final class RawPhotoUploadOperation: AssetResourceUploadOperation, @unchecked Sendable {
    override func start() {
        super.start()
        
        requestRawPhotoResource()
    }
    
    override func uploadQueueType() -> UploadQueueType {
        .photo
    }
    
    private func requestRawPhotoResource() {
        guard !isCancelled else {
            finish(with: .cancelled)
            return
        }
        
        guard let resource = uploadInfo.asset.mnz_rawImageResource else {
            finish(with: .failed)
            return
        }
        
        let fileExtension = GetFileExtensionUseCase().fileExtension(for: .image, url: nil, uniformTypeIdentifier: resource.uniformTypeIdentifier)
        do {
            uploadInfo.fileName = try mnz_generateLocalFileNamewithExtension(fileExtension)
        } catch {
            Crashlytics.crashlytics().record(error: error)
            finish(with: .failed)
            return
        }
        
        guard let url = uploadInfo.fileURL else {
            finish(with: .failed)
            return
        }
        
        export(resource, to: url, delegate: self)
    }
}

extension RawPhotoUploadOperation: AssetResourcExportDelegate {
    func assetResource(_ resource: PHAssetResource, didExportTo URL: URL) {
        handleProcessedFile(with: .image)
    }
}
