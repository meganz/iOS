//MARK: - Favourite sort by
extension Array where Element == MEGANode {
    func sort(by orderType: SortOrderType) -> [MEGANode] {
        switch orderType {
        case .nameAscending: return sortByName(.orderedAscending)
        case .nameDescending: return sortByName(.orderedDescending)
        case .largest: return sortByFileSize(.orderedDescending)
        case .smallest: return sortByFileSize(.orderedAscending)
        case .newest: return sortByDate(.orderedDescending)
        case .oldest: return sortByDate(.orderedAscending)
        case .label: return sortByLabel()
        case .favourite: return sortByFavourites()
        default: return sortByName(.orderedAscending)
        }
    }

    private func sortByName(_ order: ComparisonResult = .orderedAscending) -> [MEGANode] {
        let nodes = sorted { lhs, rhs in
            let lhsName = lhs.name ?? ""
            let rhsName = rhs.name ?? ""
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == order
        }
        return nodes
    }
    
    private func sortByFileSize(_ order: ComparisonResult = .orderedAscending) -> [MEGANode] {
        let nodes = sorted { lhs, rhs in
            let lhsName = lhs.size ?? 0
            let rhsName = rhs.size ?? 0
            return lhsName.compare(rhsName) == order
        }
        return nodes
    }
    
    private func sortByDate(_ order: ComparisonResult = .orderedAscending) -> [MEGANode] {
        let nodes = sorted { lhs, rhs in
            let lhsName = lhs.modificationTime ?? Date()
            let rhsName = rhs.modificationTime ?? Date()
            return lhsName.compare(rhsName) == order
        }
        return nodes
    }
    
    private func sortByLabel() -> [MEGANode] {
        var list: [MEGANodeLabel: [MEGANode]] = [MEGANodeLabel.red: [], MEGANodeLabel.orange: [],
                                                 MEGANodeLabel.yellow: [], MEGANodeLabel.green: [],
                                                 MEGANodeLabel.blue: [], MEGANodeLabel.purple: [],
                                                 MEGANodeLabel.grey: [], MEGANodeLabel.unknown: []]
        //Add node to assigned label color
        for node in self {
            switch node.label {
            case .red: list[.red]?.append(node)
            case .orange: list[.orange]?.append(node)
            case .yellow: list[.yellow]?.append(node)
            case .green: list[.green]?.append(node)
            case .blue: list[.blue]?.append(node)
            case .purple: list[.purple]?.append(node)
            case .grey: list[.grey]?.append(node)
            default: list[.unknown]?.append(node)
            }
        }
        
        //Sort each list and flatten list
        let nodeList = [list[.red], list[.orange], list[.yellow],
                        list[.green], list[.blue], list[.purple],
                        list[.grey], list[.unknown]]
            .compactMap({ $0 })
            .map({ $0.sortByName(.orderedAscending) })
            .flatMap({ $0 })
 
        return nodeList
    }
    
    private func sortByFavourites() -> [MEGANode] {
        let favouriteList = filter { $0.isFavourite }.sortByName()
        let notFavouriteList = filter { !$0.isFavourite }.sortByName()
        return favouriteList + notFavouriteList
    }
}
