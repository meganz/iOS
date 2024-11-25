import Foundation
import AsyncAlgorithms
@preconcurrency import Combine
@testable import CloudDrive
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellViewModel Tests")
struct NodeTagsCellViewModelTests {
    
    @Test("Check the changes of state when receiving notifications")
    func stateChange() async throws {
        let accountUseCase = MockAccountUseCase(currentAccountDetails: nil)
        let sut = await makeSut(accountUseCase: accountUseCase)
        
        #expect(await sut.state == .notDetermined)
        
        let task: Task<(), Never> = Task { @MainActor in
            await sut.startMonitoringAccountDetails()
        }
        
        let waitingTask: Task<(), Never> = Task { @MainActor in
            accountUseCase.setCurrentAccountDetails(.build(proLevel: .free))
            
            NotificationCenter.default.post(name: .accountDidFinishFetchAccountDetails, object: nil)
            await Task.megaYield()
            #expect(sut.state == .show)
            #expect(sut.isLoading == false)
            #expect(sut.showsProTag == true)
            
            NotificationCenter.default.post(name: .refreshAccountDetails, object: nil)
            await Task.megaYield()
            #expect(sut.state == .notDetermined)
            #expect(sut.isLoading == true)
            #expect(sut.showsProTag == false)
            
            accountUseCase.setCurrentAccountDetails(.build(proLevel: .proI))
            NotificationCenter.default.post(name: .accountDidFinishFetchAccountDetails, object: nil)
            await Task.megaYield()
            #expect(sut.state == .hide)
            #expect(sut.isLoading == false)
            #expect(sut.showsProTag == false)
        }
        
        await waitingTask.value
        task.cancel()
    }

    @Test(
        "Check if the user has a valid subscription",
        arguments: [true, false]
    )
    func hasValidSubscription(
        hasValidSubscription: Bool
    ) async {
        let accountUseCase = MockAccountUseCase(hasValidSubscription: hasValidSubscription)
        let sut = await makeSut(accountUseCase: accountUseCase)
        #expect(await sut.hasValidSubscription == hasValidSubscription)
    }

    @Test("Check for tags")
    func checkTags() async {
        let tags = ["tag1", "tag2", "tag3"]
        let node = NodeEntity(tags: tags)
        let sut = await makeSut(node: node)
        #expect(await sut.tags == tags)
    }
    
    private func makeSut(
        node: NodeEntity = NodeEntity(),
        accountUseCase: MockAccountUseCase = MockAccountUseCase()
    ) async -> NodeTagsCellViewModel {
        await NodeTagsCellViewModel(node: node, accountUseCase: accountUseCase, notificationCenter: .default)
    }
}

private extension Task where Success == Never, Failure == Never {
    static func megaYield(count: Int = 20) async {
        for _ in 0..<count {
            await Task<Void, Never>.detached(priority: .background) { await Task.yield() }.value
        }
    }
}
