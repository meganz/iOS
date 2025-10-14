import MEGADomain

extension AssetUploadRecordDTO {
    func toAssetUploadRecordEntity() -> CameraAssetUploadEntity? {
        guard let creationDate = creationDate else { return nil }
        return CameraAssetUploadEntity(
            localIdentifier: localIdentifier,
            creationDate: creationDate,
            mediaType: mediaType?.toPhotoAssetMediaTypeEntity() ?? .unknown,
            status: status?.toCameraAssetUploadStatusEntity() ?? .unknown)
    }
}

extension [AssetUploadRecordDTO] {
    func toAssetUploadRecordEntities() -> [CameraAssetUploadEntity] {
        compactMap { $0.toAssetUploadRecordEntity() }
    }
}
