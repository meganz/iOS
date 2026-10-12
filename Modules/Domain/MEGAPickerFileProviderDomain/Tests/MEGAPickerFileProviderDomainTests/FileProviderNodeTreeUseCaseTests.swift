import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderNodeTreeUseCaseTests {
    @Test
    func nodeTreeCaughtUp_onNodesCurrent_returnsTrue() async {
        let eventRepo = MockEventRepository()
        let sut = FileProviderNodeTreeUseCase(eventRepo: eventRepo)
        eventRepo.simulateEvent(EventEntity(type: .reloading, number: 0))
        eventRepo.simulateEvent(EventEntity(type: .nodesCurrent, number: 0))

        #expect(await sut.nodeTreeCaughtUp())
    }

    @Test
    func nodeTreeCaughtUp_whenTheUpdatesEndFirst_returnsFalse() async {
        let eventRepo = MockEventRepository()
        let sut = FileProviderNodeTreeUseCase(eventRepo: eventRepo)
        eventRepo.simulateEvent(EventEntity(type: .reloading, number: 0))
        eventRepo.simulateEventCompletion()

        #expect(await sut.nodeTreeCaughtUp() == false)
    }
}
