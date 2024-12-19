import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@testable import Settings

@Suite("FileVersioningViewModelTestSuite")
struct FileVersioningViewModelTestSuite {
    // MARK: - Helpers
    @MainActor
    private static func makeSUT(
        fileVersionsUseCase: any FileVersionsUseCaseProtocol = MockFileVersionsUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase()
    ) -> FileVersioningViewModel {
        FileVersioningViewModel(
            fileVersionsUseCase: fileVersionsUseCase,
            accountUseCase: accountUseCase
        )
    }
    
    private static func fileVersionMessage(versionCount: Int64, totalSize: Int64) -> String {
        let size = String.memoryStyleString(fromByteCount: totalSize)
        let count = Int(versionCount)
        return Strings.Localizable.Settings.FileManagement.FileVersioning.EnabledState.fileVersions(count) + " " + Strings.Localizable.Settings.FileManagement.FileVersioning.EnabledState.totalSizeTaken(count)
            .replacingOccurrences(of: "[storageSpace]", with: size)
    }
    
    struct TestCase {
        var requestResult: Result<Bool, FileVersionErrorEntity> = .failure(.generic)
        var expectedValue: Bool = false
    }
    
    // MARK: - Tests
    @Suite("Set up File versioning data")
    struct SetupFileVersioningData {
        @MainActor
        @Test("Set file version count and size")
        func setupFileVersionMessageAndCount() async {
            let randomVersionCount = Int64.random(in: 1...10)
            let randomVersionSize = Int64.random(in: 0...100)
            let sut = makeSUT(
                fileVersionsUseCase: MockFileVersionsUseCase(
                    versions: randomVersionCount,
                    versionsSize: randomVersionSize
                )
            )
            
            await sut.setupFileVersioning()
            
            #expect(sut.fileVersionCount == randomVersionCount)
            #expect(sut.fileVersionMessage == fileVersionMessage(versionCount: randomVersionCount, totalSize: randomVersionSize))
        }
        
        @MainActor
        @Test(
            "Set file versioning status if enabled or disabled",
            arguments: [
                TestCase(requestResult: .success(true), expectedValue: true),
                TestCase(requestResult: .success(false), expectedValue: false),
                TestCase(requestResult: .failure(.optionNeverSet), expectedValue: true),
                TestCase(requestResult: .failure(.generic), expectedValue: false)
            ]
        )
        func setupIsFileVersioningEnabled(testCase: TestCase) async {
            let sut = makeSUT(
                fileVersionsUseCase: MockFileVersionsUseCase(isFileVersionsEnabled: testCase.requestResult)
            )
            
            await sut.setupFileVersioning()
            
            #expect(sut.isFileVersioningEnabled == testCase.expectedValue)
        }
    }
    
    @Suite("File versioning toggle actions")
    struct ToggleFileVersioning {
        @MainActor
        @Test("Toggling off file versioning should show a disable alert first")
        func toggleOffFileVersioning() {
            let sut = makeSUT()
            
            sut.toggleFileVersioning(isCurrentlyEnabled: true)
            
            #expect(sut.showDisableAlert == true)
        }
        
        @MainActor
        @Test(
            "Toggle on file versioning",
            arguments: [
                TestCase(requestResult: .success(true), expectedValue: true),
                TestCase(requestResult: .failure(.generic), expectedValue: false)
            ]
        )
        func toggleOnFileVersioning(testCase: TestCase) async {
            let currentlyEnabled = false
            let sut = makeSUT(
                fileVersionsUseCase: MockFileVersionsUseCase(
                    isFileVersionsEnabled: .success(currentlyEnabled),
                    enableFileVersions: testCase.requestResult
                )
            )
            
            await sut.setupFileVersioning()
            sut.toggleFileVersioning(isCurrentlyEnabled: currentlyEnabled)
            await sut.updateFileVersioningTask?.value
            
            #expect(sut.isFileVersioningEnabled == testCase.expectedValue)
        }
        
        @MainActor
        @Test(
            "Tap Disable button on the Disable File versioning alert",
            arguments: [
                TestCase(requestResult: .success(false), expectedValue: false),
                TestCase(requestResult: .failure(.generic), expectedValue: true)
            ]
        )
        func disableFileVersioning(testCase: TestCase) async {
            let sut = makeSUT(
                fileVersionsUseCase: MockFileVersionsUseCase(
                    isFileVersionsEnabled: .success(true),
                    enableFileVersions: testCase.requestResult
                )
            )
            
            await sut.setupFileVersioning()
            sut.updateFileVersioning(isEnabled: false)
            await sut.updateFileVersioningTask?.value
            
            #expect(sut.isFileVersioningEnabled == testCase.expectedValue)
        }
    }
    
    @Suite("Delete all older version of files")
    struct DeleteOlderVersions {
        @MainActor
        @Test("Tapping Delete all older versions button should show alert")
        func onTapDeleteAllOlderVersionsButton() {
            let sut = makeSUT()
            
            sut.onTapDeleteAllOlderVersionsButton()
            
            #expect(sut.showDeleteOlderVersionsAlert == true)
        }
        
        @MainActor
        @Test("Delete all older versions successfully")
        func deleteOlderVersionsSucceed() async {
            let accountUseCase = MockAccountUseCase()
            let sut = makeSUT(
                fileVersionsUseCase: MockFileVersionsUseCase(
                    versions: 0,
                    versionsSize: 0,
                    deletePreviousFileVersions: .success(true)
                ),
                accountUseCase: accountUseCase
            )
            
            sut.deleteOlderVersions()
            await sut.deleteOlderVersionTask?.value
            
            #expect(sut.snackBar == .init(message: Strings.Localizable.Settings.FileManagement.FileVersioning.DeleteOlderVersions.snackBar))
            #expect(sut.isLoading == false)
            #expect(sut.fileVersionCount == 0)
            #expect(sut.fileVersionMessage == fileVersionMessage(versionCount: 0, totalSize: 0))
            #expect(accountUseCase.refreshAccountDetails_calledCount == 1)
        }
        
        @MainActor
        @Test(
            "Delete all older versions failed",
            arguments: [
                TestCase(requestResult: .success(false)),
                TestCase(requestResult: .failure(.generic))
            ]
        )
        func deleteOlderVersionsFailed(testCase: TestCase) async {
            let accountUseCase = MockAccountUseCase()
            let sut = makeSUT(
                fileVersionsUseCase: MockFileVersionsUseCase(
                    deletePreviousFileVersions: testCase.requestResult
                ),
                accountUseCase: accountUseCase
            )
            
            sut.deleteOlderVersions()
            await sut.deleteOlderVersionTask?.value
            
            #expect(sut.snackBar == nil)
            #expect(sut.isLoading == false)
            #expect(accountUseCase.refreshAccountDetails_calledCount == 0)
        }
    }
}
