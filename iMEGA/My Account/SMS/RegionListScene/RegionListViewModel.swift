import Foundation
import MEGAAppPresentation

enum RegionListAction: ActionType {
    case onViewReady
    case startSearching(String)
    case finishSearching
    case didSelectRegion(SMSRegion)
}

protocol RegionListViewRouting: Routing {
    func goToRegion(_ region: SMSRegion)
}

final class RegionListViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadIndexedRegions([[SMSRegion]], collation: UILocalizedIndexedCollation)
        case reloadSearchedRegions([SMSRegion])
    }
    
    // MARK: - Private properties
    private let router: any RegionListViewRouting
    private let sortedRegions: [SMSRegion]
    private var indexedRegions = [[SMSRegion]]()
    private let collation: UILocalizedIndexedCollation
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some RegionListViewRouting,
         regionCodes: [SMSRegion],
         collation: UILocalizedIndexedCollation = .current()) {
        self.router = router
        self.collation = collation
        self.sortedRegions = collation.sortedArray(from: regionCodes, collationStringSelector: #selector(getter: SMSRegion.displayName)) as? [SMSRegion] ?? []
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: RegionListAction) {
        switch action {
        case .onViewReady:
            indexedRegions = buildCountrySections()
            showIndexedSource()
        case .startSearching(let text):
            startSearching(text)
        case .finishSearching:
            showIndexedSource()
        case .didSelectRegion(let region):
            router.goToRegion(region)
        }
    }
    
    private func showIndexedSource() {
        invokeCommand?(.reloadIndexedRegions(indexedRegions, collation: collation))
    }
    
    private func buildCountrySections() -> [[SMSRegion]] {
        var sections = collation.sectionTitles.map { _ in [SMSRegion]() }
        for country in sortedRegions {
            let sectionIndex = collation.section(for: country, collationStringSelector: #selector(getter: SMSRegion.displayName))
            sections[sectionIndex].append(country)
        }
        
        return sections
    }
    
    // MARK: search
    private func startSearching(_ text: String) {
        let searchedRegions = sortedRegions.filter {
            $0.displayName.lowercased().contains(text.lowercased())
        }
        
        invokeCommand?(.reloadSearchedRegions(searchedRegions))
        
    }
}
