

extension MEGAPhotoBrowserViewController {
    @objc func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func reloadPhotoFavouritesIfNeeded(forNodes nodes: [MEGANode]) {
        nodes.updatePhotoFavouritesIfNeeded()
    }
}
