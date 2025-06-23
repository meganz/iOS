import MEGALogger
import SwiftUI

@MainActor
final class PlayerAppViewModel: ObservableObject {
    static let shared = PlayerAppViewModel(launchViewModel: LaunchViewModel())

    var launchViewModel: LaunchViewModel

    private let loggingUseCase: any LoggingUseCaseProtocol

    init(
        launchViewModel: LaunchViewModel,
        loggingUseCase: some LoggingUseCaseProtocol = DependencyInjection.loggingUseCase
    ) {
        self.launchViewModel = launchViewModel
        self.loggingUseCase = loggingUseCase
        loggingUseCase.prepareForLogging()
    }
}
