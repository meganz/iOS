import MEGADomain
import MEGAL10n
import MEGAUIComponent

extension MEGADomain.SortOrderEntity {
    public func toUIComponentSortOrderEntity() -> MEGAUIComponent.SortOrder {
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

extension MEGAUIComponent.SortOrder {
    public func toDomainSortOrderEntity() -> MEGADomain.SortOrderEntity {
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
        case(.linkCreated, .descending): .linkCreationDesc
        }
    }
}

extension SortOrder.Key {
    var localizedTitle: String {
        switch self {
        case .name:
            Strings.Localizable.Sorting.Name.title
        case .favourite:
            Strings.Localizable.Sorting.Favourite.title
        case .label:
            Strings.Localizable.CloudDrive.Sort.label
        case .dateAdded:
            Strings.Localizable.Sorting.DateAdded.title
        case .lastModified:
            Strings.Localizable.Sorting.LastModified.title
        case .size:
            Strings.Localizable.Sorting.Size.title
        case .shareCreated:
            Strings.Localizable.Sorting.ShareCreated.title
        case .linkCreated:
            Strings.Localizable.Sorting.LinkCreated.title
        }
    }
    
    public var sortOption: SortOption {
        SortOption(key: self, localizedTitle: localizedTitle)
    }
}

extension [SortOrder.Key] {
    public var sortOptions: [SortOption] {
        map(\.sortOption)
    }
}
