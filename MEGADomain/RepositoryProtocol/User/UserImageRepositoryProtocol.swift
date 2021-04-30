
protocol UserImageRepositoryProtocol {
    func loadUserImage(withUserHandle handle: String?,
                       destinationPath: String,
                       completion: @escaping (Result<UIImage, UserImageLoadError>) -> Void)
}
