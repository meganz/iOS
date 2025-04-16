@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("QRSettingsViewModelTests")
struct QRSettingsViewModelTests {
    final class CommandCollector {
        var commands: [QRSettingsViewModel.Command] = []
    }
    
    @MainActor private func makeSUT(
        contactLinksOptionResult: Result<Bool, any Error> = .success(true)
    ) -> (viewModel: QRSettingsViewModel, useCase: MockContactLinkVerificationUseCase, collector: CommandCollector) {
        let useCase = MockContactLinkVerificationUseCase(contactLinksOptionResult: contactLinksOptionResult)
        let viewModel = QRSettingsViewModel(contactLinkVerificationUseCase: useCase)
        let collector = CommandCollector()
        viewModel.invokeCommand = { command in
            collector.commands.append(command)
        }
        return (viewModel, useCase, collector)
    }
    
    @Test("onViewDidLoad triggers refreshAutoAccept with current value")
    @MainActor func testOnViewDidLoad() async throws {
        let (viewModel, _, collector) = makeSUT(contactLinksOptionResult: .success(true))
        viewModel.dispatch(.onViewDidLoad)
        
        await viewModel.updateAutoAcceptTask?.value
        
        #expect(collector.commands.contains { command in
            if case .refreshAutoAccept(let enabled) = command, enabled == true { return true }
            return false
        })
    }
    
    @Test("autoAcceptDidChange dispatch triggers updateContactLinksOption")
    @MainActor func testAutoAcceptDidChange() async throws {
        let (viewModel, useCase, _) = makeSUT()
        viewModel.dispatch(.autoAcceptDidChange(false))
        
        await viewModel.autoAcceptTask?.value
        
        #expect(useCase.updateContactLinksOption_calledTimes == 1)
    }
    
    @Test("resetContactLink dispatch invokes contactLinkReset command on success")
    @MainActor func testResetContactLinkSuccess() async throws {
        let (viewModel, useCase, collector) = makeSUT()
        viewModel.dispatch(.resetContactLink)
       
        await viewModel.resetContactLinkTask?.value
       
        #expect(useCase.resetContactLink_calledTimes == 1)
        #expect(collector.commands.contains { command in
            if case .contactLinkReset = command { return true }
            return false
        })
    }
    
    @Test("updateAutoAcceptCurrentValue triggers refreshAutoAccept with correct value")
    @MainActor func testUpdateAutoAcceptCurrentValue() async throws {
        let (viewModel, _, collector) = makeSUT(contactLinksOptionResult: .success(false))
        
        await viewModel.updateAutoAcceptCurrentValue()
        
        #expect(collector.commands.contains { command in
            if case .refreshAutoAccept(let value) = command, value == false { return true }
            return false
        })
    }
}
