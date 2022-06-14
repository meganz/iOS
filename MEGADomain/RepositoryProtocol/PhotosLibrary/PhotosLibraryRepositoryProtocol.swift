
protocol PhotosLibraryRepositoryProtocol {
    func copyMediaFileToPhotos(at url: URL, completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?)
}
