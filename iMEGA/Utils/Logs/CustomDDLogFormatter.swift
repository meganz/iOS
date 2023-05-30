import Foundation
import CocoaLumberjack

final class CustomDDLogFormatter: NSObject, DDLogFormatter {
    
    // MARK: - DDLogFormatter
    func format(message logMessage: DDLogMessage) -> String? {
        logMessage.message
    }
}
