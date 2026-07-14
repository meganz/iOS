import Foundation
import MEGAAppSDKRepo

// These module-internal wrappers shadow the public `MEGALog*` functions from
// MEGAAppSDKRepo so call sites across ContentLibraries don't each need to import
// it. They forward to the real implementation (which routes to `MEGASdk.log`) via
// the `MEGAAppSDKRepo.` module qualifier — without it the calls would resolve back
// to these same functions and recurse.

func MEGALogFatal(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGAAppSDKRepo.MEGALogFatal(message, file, line)
}

func MEGALogError(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGAAppSDKRepo.MEGALogError(message, file, line)
}

func MEGALogWarning(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGAAppSDKRepo.MEGALogWarning(message, file, line)
}

func MEGALogInfo(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGAAppSDKRepo.MEGALogInfo(message, file, line)
}

func MEGALogDebug(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGAAppSDKRepo.MEGALogDebug(message, file, line)
}

func MEGALogMax(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGAAppSDKRepo.MEGALogMax(message, file, line)
}
