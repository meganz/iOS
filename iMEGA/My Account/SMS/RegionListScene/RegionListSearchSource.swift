import Foundation

final class RegionListSearchSource: NSObject, RegionListSource {
    private let regions: [SMSRegion]
    
    init(regions: [SMSRegion]) {
        self.regions = regions
    }
    
    func country(at indexPath: IndexPath) -> SMSRegion {
        regions[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        regions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell(at: indexPath, in: tableView)
    }
}
