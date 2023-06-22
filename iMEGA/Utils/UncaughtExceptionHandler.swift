import FirebaseCrashlytics
import Foundation

@objc final class UncaughtExceptionHandler: NSObject {
    @objc static func registerHandler() {
        NSSetUncaughtExceptionHandler { handleException($0) }
    }
}

private func handleException(_ exception: NSException) {
    MEGALogError("Exception name: \(exception.name)\nreason: \(String(describing: exception.reason))\nuser info: \(String(describing: exception.userInfo))\n")
    MEGALogError("Stack trace: \(exception.callStackSymbols)")
    
    Crashlytics.crashlytics().record(error: exception.toUncaughtError)
}

private extension NSException {
    var toUncaughtError: NSError {
        NSError(domain: "nz.mega.uncaughtException",
                code: 0,
                userInfo: [NSLocalizedFailureReasonErrorKey: reason ?? "",
                           NSLocalizedDescriptionKey: name,
                           NSLocalizedFailureErrorKey: userInfo ?? [:],
                           NSDebugDescriptionErrorKey: callStackSymbols])
    }
}
