import Accounts
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@MainActor
@Suite("Request status progress view model test suite")
struct RequestStatusProgressViewModelTests {
    private var viewModel: RequestStatusProgressViewModel!
    private var mockRequestStatProgressUseCase: MockRequestStatProgressUseCase!

    init() {
        mockRequestStatProgressUseCase = MockRequestStatProgressUseCase()
        viewModel = RequestStatusProgressViewModel(requestStatProgressUseCase: mockRequestStatProgressUseCase)
    }

    @Test("Test initial progress is zero")
    func testInitialProgressIsZero() {
        #expect(viewModel.progress == 0)
    }

    @Test("Test progress update")
    func testGetRequestStatsProgressUpdatesProgress() async {
        let events = [
            EventEntity(number: 5),
            EventEntity(number: 10),
            EventEntity(number: -1)
        ]
        mockRequestStatProgressUseCase.events = events

        await viewModel.getRequestStatsProgress()

        #expect(viewModel.progress == 0)
    }
    
    @Test("Test opacity", arguments: [EventEntity(number: 5), EventEntity(number: -1)])
    func testOpacity(_ event: EventEntity) async {
        mockRequestStatProgressUseCase.events = [event]
        await viewModel.getRequestStatsProgress()
        if event.number == -1 {
            #expect(viewModel.opacity == 0)
        } else {
            #expect(viewModel.opacity == 1)
        }
    }
}
