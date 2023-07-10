import MEGAAnalyticsDomain
import MEGAAnalyticsiOS

final class ViewIdProviderAdapter: ViewIdProvider {
    private let viewIdUseCase: any ViewIDUseCaseProtocol
    
    init(viewIdUseCase: some ViewIDUseCaseProtocol) {
        self.viewIdUseCase = viewIdUseCase
    }
    
    func getViewIdentifier() async throws -> String {
        try viewIdUseCase.generateViewId()
    }
}
