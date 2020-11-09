import Foundation

final class RegionListIndexedSource: NSObject, RegionListSource {
    private let indexedRegions: [[SMSRegion]]
    private let collation: UILocalizedIndexedCollation
    
    init(indexedRegions: [[SMSRegion]], collation: UILocalizedIndexedCollation) {
        self.indexedRegions = indexedRegions
        self.collation = collation
    }
    
    func country(at indexPath: IndexPath) -> SMSRegion {
        indexedRegions[indexPath.section][indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        collation.sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        indexedRegions[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell(at: indexPath, in: tableView)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        collation.sectionTitles[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        collation.sectionIndexTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        collation.section(forSectionIndexTitle: index)
    }
}
