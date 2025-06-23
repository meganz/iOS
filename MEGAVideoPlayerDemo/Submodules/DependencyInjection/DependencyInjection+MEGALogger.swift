import Combine
import MEGAInfrastructure
import MEGALogger

extension DependencyInjection {
    static func composeLogger() {
        MEGALogger.DependencyInjection.sharedSdk = .sharedSdk
        MEGALogger.DependencyInjection.clientAppName = "MEGAVideoPlayerDemo"
        MEGALogger.DependencyInjection.diagnosticMessage = {
            await DiagnosticReadableCollection(
                diagnosticReadables: [
                    AppInformation(),
                    MEGAInfrastructure.DependencyInjection.deviceInformation
                ]
            ).readableDiagnostic()
        }
        MEGALogger.DependencyInjection.isDebugModePublisher = Just(true).eraseToAnyPublisher()
    }

    static var loggingUseCase: some LoggingUseCaseProtocol {
        MEGALogger.DependencyInjection.loggingUseCase
    }
}
