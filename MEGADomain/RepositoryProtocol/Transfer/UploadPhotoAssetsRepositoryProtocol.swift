
protocol UploadPhotoAssetsRepositoryProtocol {
    func upload(assets: [String], toParent parentHandle: HandleEntity)
}
