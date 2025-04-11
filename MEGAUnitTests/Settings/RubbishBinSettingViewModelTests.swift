@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import Testing

@Suite("RubbishBinSettingViewModelTests")
struct RubbishBinSettingViewModelTests {
    @MainActor
    private static func makeSUT(
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        rubbishBinSettingsUseCase: any RubbishBinSettingsUseCaseProtocol = MockRubbishBinSettingsUseCase(),
        upgradeAccountRouter: any UpgradeAccountRouting = MockUpgradeAccountRouter()
    ) -> RubbishBinSettingViewModel {
        RubbishBinSettingViewModel(accountUseCase: accountUseCase,
                                   rubbishBinSettingsUseCase: rubbishBinSettingsUseCase,
                                   upgradeAccountRouter: upgradeAccountRouter)
    }
    
    @Suite("Actions user can do on Rubbish bin setting page")
    struct ActionTests {
        @Test("Tap Upgrade Account Button")
        @MainActor
        func onTapUpgradeButtton() {
            let mockRouter = MockUpgradeAccountRouter()
            
            let sut = makeSUT(upgradeAccountRouter: mockRouter)
            
            sut.onTapUpgradeButtton()
            
            #expect(mockRouter.presentUpgradeTVCRecorder.called)
        }
        
        @Test("Tap Auto Purge Period Cell")
        @MainActor
        func onTapAutoPurgeCell() {
            let sut = makeSUT()
            
            sut.onTapAutoPurgeCell()
            
            #expect(sut.isBottomSheetPresented)
        }
        
        @Test("Tap Empty Bin Button")
        @MainActor
        func onTapEmptyBinButton() async {
            let mockRubbishbinSettingUseCase = MockRubbishBinSettingsUseCase()
            
            let sut = makeSUT(rubbishBinSettingsUseCase: mockRubbishbinSettingUseCase)
            
            sut.onTapEmptyBinButton()
            await sut.emptyRubbishBinTask?.value
            
            #expect(mockRubbishbinSettingUseCase.cleanRubbishBinCalled)
            #expect(mockRubbishbinSettingUseCase.catchupWithSDKCalled)
            #expect(sut.snackBar != nil)
            
            sut.emptyRubbishBinTask?.cancel()
        }
        
        @Test("Tap one of auto purge options such as 7 days")
        @MainActor
        func onTapAutoPurgeRow() async {
            let mockRubbishbinSettingUseCase = MockRubbishBinSettingsUseCase()
            let mockRouter = MockUpgradeAccountRouter()
            
            let sut = makeSUT(rubbishBinSettingsUseCase: mockRubbishbinSettingUseCase, upgradeAccountRouter: mockRouter)
            
            sut.onTapAutoPurgeRow(with: .oneYear)
            await sut.updateAutoPurgeTask?.value
            
            #expect(sut.selectedAutoPurgePeriod == .oneYear)
            #expect(mockRubbishbinSettingUseCase.setRubbishBinAutopurgePeriod)
            
            sut.updateAutoPurgeTask?.cancel()
        }
        
        @Test("Get rubbish bin autopurge period")
        @MainActor
        func getRubbishBinAutopurgePeriod() async {
            let rubbishBinSettingsEntity: RubbishBinSettingsEntity = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: 14, rubbishBinCleaningSchedulerEnabled: true)
            let mockUseCase = MockRubbishBinSettingsUseCase(rubbishBinSettingsEntity: rubbishBinSettingsEntity)
            
            let sut = makeSUT(rubbishBinSettingsUseCase: mockUseCase)
            
            await sut.getRubbishBinAutopurgePeriod()
            
            #expect(sut.rubbishBinAutopurgePeriod == 14)
        }
    }
}
