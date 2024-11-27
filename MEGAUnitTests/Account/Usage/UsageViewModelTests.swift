@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

@MainActor
final class UsageViewModelTests: XCTestCase {
    enum ExpectedStorage {
        static let values: [StorageType: Int64] = [
            .cloud: 1024,
            .backups: 2048,
            .rubbishBin: 512,
            .incomingShares: 256
        ]
        
        static let usedStorage: Int64 = 4096
        static let maxStorage: Int64 = 8192
        static let usedTransfer: Int64 = 4096
        static let maxTransfer: Int64 = 8192
        static let emptyMaxStorage: Int64 = 0
        static let emptyMaxTransfer: Int64 = 0
    }

    private func makeSUT(
        hasValidProAccount: Bool = false,
        rootStorage: Int64 = 0,
        backupStorage: Int64 = 0,
        rubbishBinStorage: Int64 = 0,
        incomingSharesStorage: Int64 = 0,
        currentAccountDetails: AccountDetailsEntity? = nil,
        willStorageQuotaExceed: Bool = false,
        currentStorageStatus: StorageStatusEntity = .noStorageProblems,
        shouldShowStorageBanner: Bool = false,
        isUnlimitedStorageAccount: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) -> UsageViewModel {
        let mockAccountUseCase = MockAccountUseCase(
            hasValidProAccount: hasValidProAccount,
            currentAccountDetails: currentAccountDetails,
            rootStorage: rootStorage,
            rubbishBinStorage: rubbishBinStorage,
            incomingSharesStorage: incomingSharesStorage,
            backupStorage: backupStorage
        )
        
        let mockAccountStorageUseCase = MockAccountStorageUseCase(
            willStorageQuotaExceed: willStorageQuotaExceed,
            currentStorageStatus: currentStorageStatus,
            shouldShowStorageBanner: shouldShowStorageBanner,
            isUnlimitedStorageAccount: isUnlimitedStorageAccount
        )
        
        let sut = UsageViewModel(
            accountUseCase: mockAccountUseCase,
            accountStorageUseCase: mockAccountStorageUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func runStorageTest(
        storageType: StorageType,
        expectedStorage: Int64,
        action: UsageAction,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let sut = makeSUT(
            rootStorage: storageType == .cloud ? expectedStorage : 0,
            backupStorage: storageType == .backups ? expectedStorage : 0,
            rubbishBinStorage: storageType == .rubbishBin ? expectedStorage : 0,
            incomingSharesStorage: storageType == .incomingShares ? expectedStorage : 0,
            file: file,
            line: line
        )

        test(
            viewModel: sut,
            action: action,
            expectedCommands: [
                .startLoading(storageType),
                .loaded(storageType, expectedStorage)
            ]
        )
    }
    
    func testDispatchLoadRootNodeStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .cloud,
            expectedStorage: ExpectedStorage.values[.cloud] ?? 0,
            action: .loadRootNodeStorage
        )
    }
    
    func testDispatchLoadBackupStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .backups,
            expectedStorage: ExpectedStorage.values[.backups] ?? 0,
            action: .loadBackupStorage
        )
    }
    
    func testDispatchLoadRubbishBinStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .rubbishBin,
            expectedStorage: ExpectedStorage.values[.rubbishBin] ?? 0,
            action: .loadRubbishBinStorage
        )
    }
    
    func testDispatchLoadIncomingSharedStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .incomingShares,
            expectedStorage: ExpectedStorage.values[.incomingShares] ?? 0,
            action: .loadIncomingSharedStorage
        )
    }
    
    func testLoadStorageDetails_shouldInvokeLoadedStorageCommand() {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: ExpectedStorage.usedStorage,
            storageMax: ExpectedStorage.maxStorage
        )
        
        let sut = makeSUT(currentAccountDetails: accountDetails)
        
        test(
            viewModel: sut,
            action: .loadStorageDetails,
            expectedCommands: [
                .loadedStorage(used: ExpectedStorage.usedStorage, max: ExpectedStorage.maxStorage)
            ]
        )
    }
    
    func testLoadTransferDetails_shouldInvokeLoadedTransferCommand() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: ExpectedStorage.usedTransfer,
            transferMax: ExpectedStorage.maxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        test(
            viewModel: sut,
            action: .loadTransferDetails,
            expectedCommands: [
                .loadedTransfer(used: ExpectedStorage.usedTransfer, max: ExpectedStorage.maxTransfer)
            ]
        )
    }
    
    func testCurrentStorageStatus_shouldReturnCorrectStatus() {
        let sut = makeSUT(currentStorageStatus: .almostFull)
        XCTAssertEqual(sut.currentStorageStatus, .almostFull, "Expected storage status to be 'almostFull'")
    }
    
    func testCurrentTransferStatus_whenTransferUsageBelow80Percent_shouldReturnNoTransferProblems() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: ExpectedStorage.maxTransfer / 3,
            transferMax: ExpectedStorage.maxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.currentTransferStatus, .noTransferProblems, "Expected transfer status to be 'noTransferProblems'")
    }
    
    func testCurrentTransferStatus_whenTransferUsageBetween81And99Percent_shouldReturnAlmostFull() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: ExpectedStorage.maxTransfer - 10,
            transferMax: ExpectedStorage.maxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.currentTransferStatus, .almostFull, "Expected transfer status to be 'almostFull'")
    }
    
    func testCurrentTransferStatus_whenTransferUsage100PercentOrAbove_shouldReturnFull() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: ExpectedStorage.maxTransfer,
            transferMax: ExpectedStorage.maxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.currentTransferStatus, .full, "Expected transfer status to be 'full'")
    }
    
    func testStorageUsedPercentage_shouldCalculateCorrectPercentage() {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: ExpectedStorage.maxStorage / 2,
            storageMax: ExpectedStorage.maxStorage
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.storageUsedPercentage, 50, "Expected storage used percentage to be 50%")
    }
    
    func testStorageUsedPercentage_whenStorageMaxIsZero_shouldReturnZero() {
        let accountDetails = AccountDetailsEntity.build(
            storageMax: ExpectedStorage.maxStorage
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.storageUsedPercentage, 0, "Expected storage used percentage to be 0% when storage used is nil")
    }
    
    func testStorageUsedPercentage_whenStorageUsedIsZero_shouldReturnZero() {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: ExpectedStorage.usedStorage,
            storageMax: ExpectedStorage.emptyMaxStorage
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.storageUsedPercentage, 0, "Expected storage used percentage to be 0% when storage max is 0")
    }
    
    func testTransferUsedPercentage_shouldCalculateCorrectPercentage() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: ExpectedStorage.maxTransfer / 2,
            transferMax: ExpectedStorage.maxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.transferUsedPercentage, 50, "Expected transfer used percentage to be 50%")
    }
    
    func testTransferUsedPercentage_whenTransferMaxIsZero_shouldReturnZero() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: ExpectedStorage.usedTransfer,
            transferMax: ExpectedStorage.emptyMaxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.transferUsedPercentage, 0, "Expected transfer used percentage to be 0% when transfer max is 0")
    }
    
    func testTransferUsedPercentage_whenTransfeUsedIsZero_shouldReturnZero() {
        let accountDetails = AccountDetailsEntity.build(
            transferMax: ExpectedStorage.maxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)

        XCTAssertEqual(sut.transferUsedPercentage, 0, "Expected transfer used percentage to be 0% when transfer used is nil")
    }
}
