import MEGARepo

extension MOAssetUploadFileNameRecord {
    func toAssetUploadFileNameRecordDTO(localIdentifier: String) -> AssetUploadFileNameRecordDTO? {
        .init(
            localIdentifier: localIdentifier,
            localUniqueFileName: localUniqueFileName,
            fileExtension: fileExtension
        )
    }
}
