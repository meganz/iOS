@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class UsageViewModelTests: XCTestCase {
    let rootExpectedStorage: Int64 = 1024
    let backupExpectedStorage: Int64 = 2048
    let rubbishBinExpectedStorage: Int64 = 512
    let incomingSharesExpectedStorage: Int64 = 256
    let expectedUsedStorage: Int64 = 4096
    let expectedMaxStorage: Int64 = 8192
    let expectedUsedTransfer: Int64 = 4096
    let expectedMaxTransfer: Int64 = 8192

    private func makeSUT(
        hasValidProAccount: Bool = false,
        rootStorage: Int64 = 0,
        backupStorage: Int64 = 0,
        rubbishBinStorage: Int64 = 0,
        incomingSharesStorage: Int64 = 0,
        currentAccountDetails: AccountDetailsEntity? = nil,
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
        let sut = UsageViewModel(accountUseCase: mockAccountUseCase)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

    @MainActor
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

    @MainActor
    func testDispatchLoadRootNodeStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .cloud,
            expectedStorage: rootExpectedStorage,
            action: .loadRootNodeStorage
        )
    }

    @MainActor
    func testDispatchLoadBackupStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .backups,
            expectedStorage: backupExpectedStorage,
            action: .loadBackupStorage
        )
    }

    @MainActor
    func testDispatchLoadRubbishBinStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .rubbishBin,
            expectedStorage: rubbishBinExpectedStorage,
            action: .loadRubbishBinStorage
        )
    }

    @MainActor
    func testDispatchLoadIncomingSharedStorage_shouldInvokeCorrectCommands() {
        runStorageTest(
            storageType: .incomingShares,
            expectedStorage: incomingSharesExpectedStorage,
            action: .loadIncomingSharedStorage
        )
    }

    func testIsBusinessAccount_whenProLevelIsBusiness_shouldReturnTrue() {
        let sut = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: .business))
        let result = sut.isBusinessAccount
        XCTAssertTrue(result)
    }

    func testIsProFlexiAccount_whenProLevelIsProFlexi_shouldReturnTrue() {
        let sut = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: .proFlexi))
        let result = sut.isProFlexiAccount
        XCTAssertTrue(result)
    }
    
    func testIsFreeAccount_whenFreeAccount_shouldReturnTrue() {
        let sut = makeSUT(
            currentAccountDetails: AccountDetailsEntity.build(proLevel: .free)
        )
        
        XCTAssertTrue(sut.isFreeAccount)
    }

    @MainActor func testLoadStorageDetails_shouldInvokeLoadedStorageCommand() {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: expectedUsedStorage,
            storageMax: expectedMaxStorage
        )
        
        let sut = makeSUT(currentAccountDetails: accountDetails)
        
        test(
            viewModel: sut,
            action: .loadStorageDetails,
            expectedCommands: [.loadedStorage(used: expectedUsedStorage, max: expectedMaxStorage)]
        )
    }

    @MainActor func testLoadTransferDetails_shouldInvokeLoadedTransferCommand() {
        let accountDetails = AccountDetailsEntity.build(
            transferUsed: expectedUsedTransfer,
            transferMax: expectedMaxTransfer
        )
        let sut = makeSUT(currentAccountDetails: accountDetails)
        
        test(
            viewModel: sut,
            action: .loadTransferDetails,
            expectedCommands: [.loadedTransfer(used: expectedUsedTransfer, max: expectedMaxTransfer)]
        )
    }
}
