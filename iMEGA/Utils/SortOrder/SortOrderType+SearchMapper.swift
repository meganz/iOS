import MEGADomain
import Search

extension SortOrderType {
    func toSearchSortOrderEntity() -> Search.SortOrderEntity {
        switch self {
        case .none, .nameAscending: .init(key: .name)
        case .nameDescending: .init(key: .name, direction: .descending)
        case .largest: .init(key: .size, direction: .descending)
        case .smallest: .init(key: .size)
        case .newest: .init(key: .dateAdded, direction: .descending)
        case .oldest: .init(key: .dateAdded)
        case .label: .init(key: .label)
        case .favourite: .init(key: .favourite)
        }
    }
}

extension Search.SortOrderEntity {
    func toMEGASortOrderType() -> MEGASortOrderType {
        switch (key, direction) {
        case (.name, .ascending): .defaultAsc
        case (.name, .descending): .defaultDesc
        case (.favourite, .ascending):  .favouriteAsc
        case (.favourite, .descending): .favouriteDesc
        case (.label, .ascending): .labelAsc
        case (.label, .descending): .labelDesc
        case (.dateAdded, .ascending): .creationAsc
        case (.dateAdded, .descending): .creationDesc
        case (.lastModified, .ascending): .modificationAsc
        case (.lastModified, .descending): .modificationDesc
        case (.size, .ascending): .sizeAsc
        case (.size, .descending): .sizeDesc
        case (.shareCreated, .ascending): .shareCreationAsc
        case (.shareCreated, .descending): .shareCreationDesc
        case (.linkCreated, .ascending): .linkCreationAsc
        case(.linkCreated, .descending): .linkCreationDesc
        }
    }

    func toDomainSortOrderEntity() -> MEGADomain.SortOrderEntity {
        switch (key, direction) {
        case (.name, .ascending): .defaultAsc
        case (.name, .descending): .defaultDesc
        case (.favourite, .ascending): .favouriteAsc
        case (.favourite, .descending): .favouriteDesc
        case (.label, .ascending): .labelAsc
        case (.label, .descending): .labelDesc
        case (.dateAdded, .ascending): .creationAsc
        case (.dateAdded, .descending): .creationDesc
        case (.lastModified, .ascending): .modificationAsc
        case (.lastModified, .descending): .modificationDesc
        case (.size, .ascending): .sizeAsc
        case (.size, .descending): .sizeDesc
        case (.shareCreated, .ascending): .shareCreationAsc
        case (.shareCreated, .descending): .shareCreationDesc
        case (.linkCreated, .ascending): .linkCreationAsc
        case (.linkCreated, .descending): .linkCreationDesc
        }
    }
}

extension MEGADomain.SortOrderEntity {
    func toSearchSortOrderEntity() -> Search.SortOrderEntity {
        if self == .none {
            MEGALogDebug("Invalid case found \(self)")
        }

        return switch self {
        case .none, .defaultAsc: .init(key: .name)
        case .defaultDesc: .init(key: .name, direction: .descending)
        case .sizeAsc: .init(key: .size)
        case .sizeDesc: .init(key: .size, direction: .descending)
        case .creationAsc: .init(key: .dateAdded)
        case .creationDesc: .init(key: .dateAdded, direction: .descending)
        case .modificationAsc: .init(key: .lastModified)
        case .modificationDesc: .init(key: .lastModified, direction: .descending)
        case .labelAsc: .init(key: .label)
        case .labelDesc: .init(key: .label, direction: .descending)
        case .favouriteAsc: .init(key: .favourite)
        case .favouriteDesc: .init(key: .favourite, direction: .descending)
        case .shareCreationAsc: .init(key: .shareCreated)
        case .shareCreationDesc: .init(key: .shareCreated, direction: .descending)
        case .linkCreationAsc: .init(key: .linkCreated)
        case .linkCreationDesc: .init(key: .linkCreated, direction: .descending)
        }
    }
}
