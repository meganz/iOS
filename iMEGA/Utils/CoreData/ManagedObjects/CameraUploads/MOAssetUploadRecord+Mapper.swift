import MEGARepo

extension MOAssetUploadRecord {
    func toAssetUploadRecordDTO() -> AssetUploadRecordDTO? {
        guard let localIdentifier else { return nil }
        let uploadStatus: CameraAssetUploadStatusDTO = if let statusIntValue = status?.intValue,
                                                          let assetUploadStatus = CameraAssetUploadStatus(rawValue: statusIntValue) {
            assetUploadStatus.toCameraAssetUploadStatusDTO()
        } else {
            .unknown
        }
        return .init(
            localIdentifier: localIdentifier,
            creationDate: creationDate,
            mediaType: PHAssetMediaType(rawValue: mediaType?.intValue ?? 0),
            mediaSubtypes: mediaSubtypes?.uintValue,
            additionalMediaSubtypes: additionalMediaSubtypes?.intValue,
            status: uploadStatus)
    }
}

extension [MOAssetUploadRecord] {
    func toAssetUploadRecordDTOs() -> [AssetUploadRecordDTO] {
        compactMap { $0.toAssetUploadRecordDTO() }
    }
}
