import Foundation

extension Array where Element: PhotoDateSection {
    func toDataSourceSnapshot() -> NSDiffableDataSourceSnapshot<PhotoDateSection, PhotoDateSection.Content> {
        var snapshot = NSDiffableDataSourceSnapshot<PhotoDateSection, PhotoDateSection.Content>()
        
        for section in self {
            snapshot.appendSections([section])
            snapshot.appendItems(section.contentList, toSection: section)
        }
        
        return snapshot
    }
}
