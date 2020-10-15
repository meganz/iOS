
extension IndexPath {
    var previousSectionIndexPath: IndexPath? {
        guard section > 0 else { return nil }

        let previousIndexPath = IndexPath(item: item, section: section - 1)
        return previousIndexPath
    }
}
