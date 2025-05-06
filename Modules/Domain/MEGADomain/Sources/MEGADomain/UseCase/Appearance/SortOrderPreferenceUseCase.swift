import Combine
import Foundation
import MEGAPreference

/// Use case to manage sorting preferences for features and folders in the application
public protocol SortOrderPreferenceUseCaseProtocol {
    
    /// Fetches the desired sort order for the given preference key, if an appearance model exists for the given key. Depending on users desired setting for applying sort logic. This may not fetch based on the passed key but instead use a global sort order.
    /// - Parameter key: SortOrderPreferenceKeyEntity associated with a feature or context of the application
    /// - Returns: SortOrderEntity that describes the order in which the context should be applied in
    func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity
    
    /// Fetches the desired sort order for the given NodeEntity/Folder, if an appearance model exists for the given node. Depending on users desired setting for applying sort logic. This may not fetch based on the passed node but instead use a global sort order.
    /// - Parameter node: NodeEntity associated with a parent folder node.
    /// - Returns: SortOrderEntity that describes the order in which the contents of a parent folder should be sorted. If nil node provided it will return either the global sort order or the default sort type based on users SortingPreferenceBasisEntity preference
    func sortOrder(for node: NodeEntity?) -> SortOrderEntity
    
    /// Save the given sortOrder appearance information associated to the given key. Depending on users desired setting for applying sort logic. This may not save  on the passed key but instead save at a global associated level.
    /// - Parameters:
    ///   - sortOrder: The desired sort order appearance to save against the associated key value.
    ///   - key: Key identifying on which target to save this sort order preference against.
    func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity)
    
    /// Save the given sortOrder appearance information associated to the given key. Depending on users desired setting for applying sort logic. This may not save  on the passed node but instead save at a global associated level.
    /// - Parameters:
    ///   - sortOrder: The desired sort order appearance to save against the associated key value.
    ///   - node: Node identifying on which target to save this sort order preference against.
    func save(sortOrder: SortOrderEntity, for node: NodeEntity)
    
    /// Monitor and emit SortOrderEntity changes for the given key only. This publisher will only emit new SortOrderEntity values without emitting duplicates when the value for the given key changes only.
    /// - Parameter key: SortOrderPreferenceKeyEntity associated with a feature or context of the application
    /// - Returns: A publisher that emits the SortOrderEntity for the given key, upon subscription it will emit the current value assigned to the key
    func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never>

    /// Monitor and emit SortOrderEntity changes for the given node only. This publisher will only emit new SortOrderEntity values without emitting duplicates when the value for the given key changes only.
    /// - Parameter node: NodeEntity associated with a parent folder node
    /// - Returns: A publisher that emits the SortOrderEntity for the given key, upon subscription it will emit the current value assigned to the node
    func monitorSortOrder(for node: NodeEntity) -> AnyPublisher<SortOrderEntity, Never>
}

public struct SortOrderPreferenceUseCase<T: PreferenceUseCaseProtocol, U: SortOrderPreferenceRepositoryProtocol>: SortOrderPreferenceUseCaseProtocol {
        
    @PreferenceWrapper(key: PreferenceKeyEntity.sortingPreference, defaultValue: nil)
    private var userSortingAssignmentPreferenceRawType: Int?
    private var userSortingAssignmentPreference: SortingPreferenceBasisEntity {
        guard let userSortingAssignmentPreferenceRawType,
              let sortingPreferenceBasisEntity = sortOrderPreferenceRepository.sortOrderPreferenceBasis(for: userSortingAssignmentPreferenceRawType) else {
            return .perFolder
        }
        return sortingPreferenceBasisEntity
    }
    
    @PreferenceWrapper(key: PreferenceKeyEntity.sortingPreferenceType, defaultValue: nil)
    private var usersSortOrderPreferenceRawType: Int?
    private var usersSortOrderPreferenceType: SortOrderEntity {
        guard let usersSortOrderPreferenceRawType,
              let sortOrderEntity = sortOrderPreferenceRepository.sortOrder(for: usersSortOrderPreferenceRawType)else {
            return .defaultAsc
        }
        return sortOrderEntity
    }
    
    private let sortOrderPreferenceRepository: U
    private let notificationCenter: NotificationCenter
    
    public init(preferenceUseCase: T,
                sortOrderPreferenceRepository: U,
                notificationCenter: NotificationCenter = .default) {
        self.sortOrderPreferenceRepository = sortOrderPreferenceRepository
        self.notificationCenter = notificationCenter
        
        $userSortingAssignmentPreferenceRawType.useCase = preferenceUseCase
        $usersSortOrderPreferenceRawType.useCase = preferenceUseCase
    }
    
    public func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity {
        switch userSortingAssignmentPreference {
        case .perFolder:
            return sortOrderPreferenceRepository.sortOrder(for: key) ?? .defaultAsc
        case .sameForAll:
            return usersSortOrderPreferenceType
        }
    }
    
    public func sortOrder(for node: NodeEntity?) -> SortOrderEntity {
        switch userSortingAssignmentPreference {
        case .perFolder:
            guard let node else { return .defaultAsc }
            return sortOrderPreferenceRepository.sortOrder(for: node) ?? .defaultAsc
        case .sameForAll:
            return usersSortOrderPreferenceType
        }
    }
    
    public func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) {
        switch userSortingAssignmentPreference {
        case .perFolder:
            sortOrderPreferenceRepository.save(sortOrder: sortOrder, for: key)
        case .sameForAll:
            usersSortOrderPreferenceRawType = sortOrderPreferenceRepository.megaSortOrderTypeCode(for: sortOrder)
        }
        notificationCenter.post(name: .sortingPreferenceChanged, object: nil)
    }
    
    public func save(sortOrder: SortOrderEntity, for node: NodeEntity) {
        switch userSortingAssignmentPreference {
        case .perFolder:
            sortOrderPreferenceRepository.save(sortOrder: sortOrder, for: node)
        case .sameForAll:
            usersSortOrderPreferenceRawType =  sortOrderPreferenceRepository.megaSortOrderTypeCode(for: sortOrder)
        }
        notificationCenter.post(name: .sortingPreferenceChanged, object: nil)
    }
    
    public func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never> {
        notificationCenter
            .publisher(for: .sortingPreferenceChanged)
            .compactMap { _ in sortOrder(for: key) }
            .prepend(sortOrder(for: key))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public func monitorSortOrder(for node: NodeEntity) -> AnyPublisher<SortOrderEntity, Never> {
        notificationCenter
            .publisher(for: .sortingPreferenceChanged)
            .compactMap { _ in sortOrder(for: node) }
            .prepend(sortOrder(for: node))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
