import MEGADomain

extension AssetUploadFileNameRecordDTO {
    func toCameraUploadFileDetailsEntity() -> CameraUploadFileDetailsEntity? {
        guard let fileName = localUniqueFileName,
                let fileExtension else { return nil }
        return .init(localIdentifier: localIdentifier,
                     fileName: fileName,
                     fileExtension: fileExtension)
    }
}

extension [AssetUploadFileNameRecordDTO] {
    func toCameraUploadFileDetailsEntities() -> [CameraUploadFileDetailsEntity] {
        compactMap { $0.toCameraUploadFileDetailsEntity() }
    }
}
