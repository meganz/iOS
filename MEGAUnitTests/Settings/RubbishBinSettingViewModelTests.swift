@testable import MEGA

import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
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
        func onTapEmptyBinButton() {
            let mockRubbishbinSettingUseCase = MockRubbishBinSettingsUseCase()
            
            let sut = makeSUT(rubbishBinSettingsUseCase: mockRubbishbinSettingUseCase)
            
            sut.onTapEmptyBinButton()
            
            #expect(mockRubbishbinSettingUseCase.cleanRubbishBinCalled)
        }
        
        @Test("Tap one of auto purge options such as 7 days")
        @MainActor
        func onTapAutoPurgeRow() {
            let mockRubbishbinSettingUseCase = MockRubbishBinSettingsUseCase()
            let mockRouter = MockUpgradeAccountRouter()
            
            let sut = makeSUT(rubbishBinSettingsUseCase: mockRubbishbinSettingUseCase, upgradeAccountRouter: mockRouter)
            
            sut.onTapAutoPurgeRow(with: .oneYear)
            
            #expect(sut.selectedAutoPurgePeriod == .oneYear)
        }
    }
    
    @Suite("Monitor Rubbish Bin Settings Updates")
    struct RubbishBinSettingUpdates {
        
        @Test("Successful call back only")
        @MainActor
        func onRequestFinishSuccess() async {
            let succeedResult: Result<RubbishBinSettingsEntity, any Error> = .success(RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: 14, rubbishBinCleaningSchedulerEnabled: true))
            let mockUseCase = MockRubbishBinSettingsUseCase(onRubbishBinSettinghsRequestFinish: SingleItemAsyncSequence(item: succeedResult).eraseToAnyAsyncSequence())
            
            let sut = makeSUT(rubbishBinSettingsUseCase: mockUseCase)
            
            let task = Task {
                await sut.startRubbishBinSettingsUpdatesMonitoring()
            }
            
            await task.value
            
            #expect(sut.rubbishBinAutopurgePeriod == 14)
            
            task.cancel()
        }
    }
}
