
extension Array where Element == MEGANode {
    func updatePhotoFavouritesIfNeeded() {
        let updatedNodes = modifiedFavourites().map({ $0.toNodeEntity() })
        if !updatedNodes.isEmpty {
            NotificationCenter.default.post(name: .didPhotoFavouritesChange, object: updatedNodes)
        }
    }
}
