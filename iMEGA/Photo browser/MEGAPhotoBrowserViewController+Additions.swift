
extension MEGAPhotoBrowserViewController {
    @objc func reloadPhotoFavouritesIfNeeded(forNodes nodes: [MEGANode]) {
        nodes.updatePhotoFavouritesIfNeeded()
    }
}
