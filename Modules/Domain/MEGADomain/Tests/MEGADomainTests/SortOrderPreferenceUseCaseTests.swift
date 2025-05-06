import Combine
import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

final class SortOrderPreferenceUseCaseTests: XCTestCase {
    
    // MARK: SortOrderForKeys
    
    func testSortOrderForKeys_whenUsersSortingPreferenceEqualsPerFolder_shouldReturnValueSavedInSortOrderRepo() {
        SortOrderEntity.allCases.forEach { repoSortOrderValue in
            // Arrange
            let sut = makeSut(
                sortingPreference: .perFolder,
                keyedSortOrderPreferenceValues: [.cameraUploadExplorerFeed: repoSortOrderValue])
            
            // Act
            let result = sut.sortOrder(for: .cameraUploadExplorerFeed)
            
            // Assert
            XCTAssertEqual(result, repoSortOrderValue)
        }
    }
    
    func testSortOrderForKey_whenUsersSortingPreferenceEqualsPerFolderAndStoredPreferenceValueIsNil_shouldReturnValuePreferenceDefaultValue() {
        // Arrange
        let sut = makeSut(
            sortingPreference: .perFolder)
        
        // Act
        let result = sut.sortOrder(for: .cameraUploadExplorerFeed)
        
        // Assert
        XCTAssertEqual(result, .defaultAsc)
    }

    func testSortOrderForKeys_whenUsersSortingPreferenceEqualsSameForAll_shouldReturnValueStoredInPrefrences() {
        SortOrderEntity.allCases.forEach { repoSortOrderValue in
            // Arrange
            let sortingPreferenceRawType = 2

            let sut = makeSut(
                sortingPreference: .sameForAll,
                sortingPreferenceTypeRawValue: sortingPreferenceRawType,
                megaSortOrderTypeCodes: [repoSortOrderValue: sortingPreferenceRawType])
            
            // Act
            let result = sut.sortOrder(for: .cameraUploadExplorerFeed)
            
            // Assert
            XCTAssertEqual(result, repoSortOrderValue)
        }
    }
    
    func testSortOrderForKey_whenUsersSortingPreferenceEqualsSameForAllAndStoredPreferenceValueIsNil_shouldReturnValuePreferenceDefaultValue() {
        // Arrange
        let sut = makeSut(
            sortingPreference: .sameForAll)
        
        // Act
        let result = sut.sortOrder(for: .cameraUploadExplorerFeed)
        
        // Assert
        XCTAssertEqual(result, .defaultAsc)
    }
    
    // MARK: SortOrderForNode
    
    func testSortOrderForNode_whenUsersSortingPreferenceEqualsPerFolder_shouldReturnValueSavedInSortOrderRepo() {
        SortOrderEntity.allCases.forEach { repoSortOrderValue in
            // Arrange
            let nodeEntity = NodeEntity(handle: 1)
            let sut = makeSut(
                sortingPreference: .perFolder,
                nodeSortOrderPreferenceValues: [nodeEntity: repoSortOrderValue])
            
            // Act
            let result = sut.sortOrder(for: nodeEntity)
            
            // Assert
            XCTAssertEqual(result, repoSortOrderValue)
        }
    }
    
    func testSortOrderForNode_whenUsersSortingPreferenceEqualsPerFolderAndStoredPreferenceValueIsNil_shouldReturnValuePreferenceDefaultValue() {
        // Arrange
        let sut = makeSut(
            sortingPreference: .perFolder)

        // Act
        let result = sut.sortOrder(for: NodeEntity(handle: 1))

        // Assert
        XCTAssertEqual(result, .defaultAsc)
    }

    func testSortOrderForNode_whenUsersSortingPreferenceEqualsSameForAll_shouldReturnValueStoredInPrefrences() {
        SortOrderEntity.allCases.forEach { repoSortOrderValue in
            // Arrange
            let nodeEntity = NodeEntity(handle: 1)
            let sortingPreferenceRawType = 2
            let sut = makeSut(
                sortingPreference: .sameForAll,
                sortingPreferenceTypeRawValue: sortingPreferenceRawType,
                nodeSortOrderPreferenceValues: [nodeEntity: repoSortOrderValue],
                megaSortOrderTypeCodes: [repoSortOrderValue: sortingPreferenceRawType]
            )

            // Act
            let result = sut.sortOrder(for: nodeEntity)

            // Assert
            XCTAssertEqual(result, repoSortOrderValue)
        }
    }
    
    func testSortOrderForNode_whenUsersSortingPreferenceEqualsSameForAllAndStoredPreferenceValueIsNil_shouldReturnValuePreferenceDefaultValue() {
        // Arrange
        let sut = makeSut(
            sortingPreference: .sameForAll)

        // Act
        let result = sut.sortOrder(for: NodeEntity(handle: 1))
        
        // Assert
        XCTAssertEqual(result, .defaultAsc)
    }
    
    // MARK: SaveSortOrderForKey
    
    func testSaveSortOrderForKeys_whenUsersSortingPreferenceEqualsSameForAll_shouldSaveInPreferencesOnly() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [
            PreferenceKeyEntity.sortingPreference.rawValue: 1,
            PreferenceKeyEntity.sortingPreferenceType.rawValue: Int?.none as Any
        ])
        
        let sortOrderPreferenceRepository = makeMockSortOrderPreferenceRepository(
            megaSortOrderTypeCodes: [.favouriteDesc: 2],
            sortOrderPreferenceBasisCodes: [.sameForAll: 1]
        )
        
        let sut = makeSut(
            preferenceUseCase: preferenceUseCase,
            sortOrderPreferenceRepository: sortOrderPreferenceRepository)

        let savedValue: SortOrderEntity = .favouriteDesc

        // Act
        sut.save(sortOrder: savedValue, for: .cameraUploadExplorerFeed)
        
        // Arrange
        XCTAssertEqual(preferenceUseCase.dict[PreferenceKeyEntity.sortingPreferenceType.rawValue] as? Int, 2)
        XCTAssertEqual(sortOrderPreferenceRepository.saveSortOrderForKey_calledCount, 0)
        XCTAssertEqual(sortOrderPreferenceRepository.keySortedEntity[.cameraUploadExplorerFeed], nil)
    }
    
    func testSaveSortOrderForKeys_whenUsersSortingPreferenceEqualsPerFolder_shouldSaveInSortOrderRepoOnly() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [
            PreferenceKeyEntity.sortingPreference.rawValue: 1,
            PreferenceKeyEntity.sortingPreferenceType.rawValue: Int?.none as Any
        ])
        
        let sortOrderPreferenceRepository = makeMockSortOrderPreferenceRepository(
            megaSortOrderTypeCodes: [.favouriteDesc: 2],
            sortOrderPreferenceBasisCodes: [.perFolder: 1]
        )

        let sut = makeSut(
            preferenceUseCase: preferenceUseCase,
            sortOrderPreferenceRepository: sortOrderPreferenceRepository)

        let savedValue: SortOrderEntity = .favouriteDesc

        // Act
        sut.save(sortOrder: savedValue, for: .cameraUploadExplorerFeed)
        
        // Arrange
        XCTAssertEqual(preferenceUseCase.dict[PreferenceKeyEntity.sortingPreferenceType.rawValue] as? Int, nil)
        XCTAssertEqual(sortOrderPreferenceRepository.saveSortOrderForKey_calledCount, 1)
        XCTAssertEqual(sortOrderPreferenceRepository.keySortedEntity[.cameraUploadExplorerFeed], savedValue)
    }
    
    // MARK: SaveSortOrderForNode
    
    func testSaveSortOrderForNode_whenUsersSortingPreferenceEqualsSameForAll_shouldSaveInPreferencesOnly() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [
            PreferenceKeyEntity.sortingPreference.rawValue: 1,
            PreferenceKeyEntity.sortingPreferenceType.rawValue: Int?.none as Any
        ])
        
        let sortOrderPreferenceRepository = makeMockSortOrderPreferenceRepository(
            megaSortOrderTypeCodes: [.favouriteDesc: 2],
            sortOrderPreferenceBasisCodes: [.sameForAll: 1]
        )
        let sut = makeSut(
            preferenceUseCase: preferenceUseCase,
            sortOrderPreferenceRepository: sortOrderPreferenceRepository)
        
        let savedValue: SortOrderEntity = .favouriteDesc
        let nodeEntity = NodeEntity(handle: 1)
        // Act
        sut.save(sortOrder: savedValue, for: nodeEntity)
        
        // Arrange
        XCTAssertEqual(preferenceUseCase.dict[PreferenceKeyEntity.sortingPreferenceType.rawValue] as? Int, 2)
        XCTAssertEqual(sortOrderPreferenceRepository.saveSortOrderForKey_calledCount, 0)
        XCTAssertEqual(sortOrderPreferenceRepository.nodeSortedEntity[nodeEntity], nil)
    }
    
    func testSaveSortOrderForNode_whenUsersSortingPreferenceEqualsPerFolder_shouldSaveInSortOrderRepoOnly() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [
            PreferenceKeyEntity.sortingPreference.rawValue: 1,
            PreferenceKeyEntity.sortingPreferenceType.rawValue: Int?.none as Any
        ])
        
        let sortOrderPreferenceRepository = makeMockSortOrderPreferenceRepository(
            sortOrderPreferenceBasisCodes: [.perFolder: 1]
        )
        
        let sut = makeSut(
            preferenceUseCase: preferenceUseCase,
            sortOrderPreferenceRepository: sortOrderPreferenceRepository)
        
        let savedValue: SortOrderEntity = .favouriteDesc
        let nodeEntity = NodeEntity(handle: 1)

        // Act
        sut.save(sortOrder: savedValue, for: nodeEntity)
        
        // Arrange
        XCTAssertEqual(preferenceUseCase.dict[PreferenceKeyEntity.sortingPreferenceType.rawValue] as? Int, nil)
        XCTAssertEqual(sortOrderPreferenceRepository.saveSortOrderForKey_calledCount, 0)
        XCTAssertEqual(sortOrderPreferenceRepository.nodeSortedEntity[nodeEntity], savedValue)
    }
    
    // MARK: Monitor
    
    func testMonitorSortOrderForKey_whenCallingSave_shouldEmitNonDuplicatedEvents() async {
        let notificationCenter = NotificationCenter()
        let sut = makeSut(notificationCenter: notificationCenter)
        let key: SortOrderPreferenceKeyEntity = .cameraUploadExplorerFeed

        let exp = expectation(description: "Should emit sort order models")
        var results: [SortOrderEntity] = []
        var subscriptions = Set<AnyCancellable>()
        
        sut.monitorSortOrder(for: key)
            .collect(.byTime(DispatchQueue.main, .seconds(0.5)))
            .sink { values in
                results = values
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.save(sortOrder: .labelAsc, for: key)
        sut.save(sortOrder: .labelAsc, for: key)
        sut.save(sortOrder: .favouriteAsc, for: key)
        
        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertEqual(results, [.defaultAsc, .labelAsc, .favouriteAsc])
    }
    
    func testMonitorSortOrderForNode_whenCallingSave_shouldEmitNonDuplicatedEvents() async {
        let notificationCenter = NotificationCenter()
        let sut = makeSut(notificationCenter: notificationCenter)
        let nodeEntity = NodeEntity(handle: 1)
        
        let exp = expectation(description: "Should emit sort order models")
        var wantedResults: [SortOrderEntity] = []
        var unwantedResults: [SortOrderEntity] = []
        var subscriptions = Set<AnyCancellable>()
        sut.monitorSortOrder(for: nodeEntity)
            .collect(.byTime(DispatchQueue.main, .seconds(0.5)))
            .sink { values in
                wantedResults = values
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.monitorSortOrder(for: NodeEntity(handle: 2))
            .sink { unwantedResults.append($0) }
            .store(in: &subscriptions)
        
        sut.save(sortOrder: .labelAsc, for: nodeEntity)
        sut.save(sortOrder: .labelAsc, for: nodeEntity)
        sut.save(sortOrder: .favouriteAsc, for: nodeEntity)
        
        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertEqual(wantedResults, [.defaultAsc, .labelAsc, .favouriteAsc])
        XCTAssertEqual(unwantedResults, [.defaultAsc])
    }
    
    func makeSut(
        sortingPreference: SortingPreferenceBasisEntity,
        sortingPreferenceTypeRawValue: Int? = nil,
        keyedSortOrderPreferenceValues: [SortOrderPreferenceKeyEntity: SortOrderEntity] = [:],
        nodeSortOrderPreferenceValues: [NodeEntity: SortOrderEntity] = [:],
        megaSortOrderTypeCodes: [SortOrderEntity: Int] = [:]) -> SortOrderPreferenceUseCase<MockPreferenceUseCase, MockSortOrderPreferenceRepository> {
            
            let sortOrderPreferenceBasisCodes: [SortingPreferenceBasisEntity: Int] = SortingPreferenceBasisEntity.allCases
                .enumerated()
                .reduce(into: [SortingPreferenceBasisEntity: Int](), { $0[$1.element] = $1.offset })
            
            let preferenceUseCase = MockPreferenceUseCase(dict: [
                PreferenceKeyEntity.sortingPreference.rawValue: sortOrderPreferenceBasisCodes[sortingPreference] as Any,
                PreferenceKeyEntity.sortingPreferenceType.rawValue: sortingPreferenceTypeRawValue as Any
            ])
                        
            let sortOrderPreferenceRepository = makeMockSortOrderPreferenceRepository(
                keyedSortOrderPreferenceValues: keyedSortOrderPreferenceValues,
                nodeSortOrderPreferenceValues: nodeSortOrderPreferenceValues,
                megaSortOrderTypeCodes: megaSortOrderTypeCodes,
                sortOrderPreferenceBasisCodes: sortOrderPreferenceBasisCodes)
            
            return SortOrderPreferenceUseCase(
                preferenceUseCase: preferenceUseCase,
                sortOrderPreferenceRepository: sortOrderPreferenceRepository)
        }
    
    func makeSut(
        preferenceUseCase: some MockPreferenceUseCase = MockPreferenceUseCase(),
        sortOrderPreferenceRepository: some MockSortOrderPreferenceRepository = MockSortOrderPreferenceRepository(),
        notificationCenter: NotificationCenter = NotificationCenter()) -> SortOrderPreferenceUseCase<MockPreferenceUseCase, MockSortOrderPreferenceRepository> {
            
            return SortOrderPreferenceUseCase(
                preferenceUseCase: preferenceUseCase,
                sortOrderPreferenceRepository: sortOrderPreferenceRepository,
                notificationCenter: notificationCenter)
        }
    
    func makeMockSortOrderPreferenceRepository(
        keyedSortOrderPreferenceValues: [SortOrderPreferenceKeyEntity: SortOrderEntity] = [:],
        nodeSortOrderPreferenceValues: [NodeEntity: SortOrderEntity] = [:],
        megaSortOrderTypeCodes: [SortOrderEntity: Int] = [:],
        sortOrderPreferenceBasisCodes: [SortingPreferenceBasisEntity: Int] = [:]) -> MockSortOrderPreferenceRepository {
            
        return MockSortOrderPreferenceRepository(
            megaSortOrderTypeCodes: megaSortOrderTypeCodes,
            sortOrderPreferenceBasisCodes: sortOrderPreferenceBasisCodes,
            keySortedEntity: keyedSortOrderPreferenceValues,
            nodeSortedEntity: nodeSortOrderPreferenceValues)
    }
}
