import AsyncAlgorithms
import Combine
import MEGADomain
import MEGAL10n

@MainActor
public final class AppLoadingViewModel: ObservableObject {
    private let appLoadingUseCase: any AppLoadingUseCaseProtocol
    private let requestStatProgressUseCase: any RequestStatProgressUseCaseProtocol
    
    let totalProgress: Double = 1000
    
    enum AppLoadingViewState: Equatable {
        case initialized
        case loading(percentage: Double)
        case error(reason: String)
        case completed
    }
    
    private let appLoadComplete: ( @MainActor @Sendable () -> Void)?
    
    @Published private(set) var status: AppLoadingViewState = .initialized
    
    var progress: Double? {
        if case let .loading(percentage) = status {
            return percentage
        }
        return nil
    }
    
    var statusText: String {
        switch status {
        case .initialized:
            Strings.Localizable.Login.connectingToServer
        case .loading:
            Strings.Localizable.Login.downloadFilelist
        case .error(let reason):
            reason
        case .completed:
            Strings.Localizable.Login.preparingFileList
        }
    }
    
    public init(
        appLoadingUseCase: some AppLoadingUseCaseProtocol,
        requestStatProgressUseCase: some RequestStatProgressUseCaseProtocol,
        appLoadComplete: ( @MainActor @Sendable () -> Void)? = nil
    ) {
        self.appLoadingUseCase = appLoadingUseCase
        self.requestStatProgressUseCase = requestStatProgressUseCase
        self.appLoadComplete = appLoadComplete
    }
    
    func onViewAppear() async {
        for await newStatus in statusStream {
            self.status = newStatus
        }
    }
    
    var statusStream: AsyncStream<AppLoadingViewState> {
        AsyncStream { continuation in
            Task {
                let reqStatsProgressStream = requestStatProgressUseCase.requestStatsProgress
                    .map { event in
                        event.number == -1 ? AppLoadingViewState.loading(percentage: 0) : AppLoadingViewState.loading(percentage: Double(event.number))
                    }
                
                let appLoadingUpdatesStream = appLoadingUseCase.appLoadingUpdates
                    .map { requestEntity in
                        AppLoadingViewState.loading(percentage: requestEntity.progress)
                    }
                
                let appLoadingTemporaryErrorUpdatesStream = appLoadingUseCase.appLoadingTemporaryErrorUpdates
                    .map { [weak self] _ in
                        AppLoadingViewState.error(reason: self?.appLoadingUseCase.waitingReason.message ?? "")
                    }
                
                let appLoadingFinishUpdatesStream = appLoadingUseCase.appLoadingFinishUpdates
                    .compactMap { [weak self] result in
                        if case let .success(request) = result, request.type == .fetchNodes {
                            await self?.appLoadComplete?()
                            return AppLoadingViewState.completed
                        }
                        return nil
                    }
                
                let appLoadingStream = merge(appLoadingUpdatesStream, appLoadingTemporaryErrorUpdatesStream, appLoadingFinishUpdatesStream)
                    
                for await newState in merge(reqStatsProgressStream, appLoadingStream) {
                    continuation.yield(newState)
                }
            }
        }
    }
}
