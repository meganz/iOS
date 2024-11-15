import Combine
import MEGADomain

@MainActor
public final class RequestStatusProgressViewModel: ObservableObject {
    private let requestStatProgressUseCase: any RequestStatProgressUseCaseProtocol
    
    @Published public var progress: Double = 0
    
    let total: Double = 1000 // Per mil progress
    
    public var opacity: Double {
        progress == 0 ? 0 : 1
    }
    
    public init(requestStatProgressUseCase: some RequestStatProgressUseCaseProtocol) {
        self.requestStatProgressUseCase = requestStatProgressUseCase
    }
    
    public func getRequestStatsProgress() async {
        for await event in requestStatProgressUseCase.requestStatsProgress {
            if event.number == -1 {
                progress = 0
            } else {
                progress = Double(event.number)
            }
        }
    }
}
