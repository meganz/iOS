@testable import MEGA

final class MockExportFileViewRouter: ExportFileViewRouting {
    var exportedFiles_calledTimes = 0
    var showProgressView_calledTimes = 0
    var hideProgressView_calledTimes = 0
    var exportedUrls: [URL] = []
    /// The counts the warning was raised with, in call order, so a test can assert it was raised once and
    /// with the figures the copy quotes.
    var warnDownloadIncompleteInvocations: [(downloadedCount: Int, failedCount: Int)] = []
    /// Run while the warning is being raised, standing in for the window the real router holds open with an
    /// alert on screen — long enough for a test to act on the export that is waiting behind it.
    var onWarnDownloadIncomplete: (() -> Void)?

    func exportedFiles(urls: [URL]) {
        exportedFiles_calledTimes += 1
        exportedUrls = urls
    }
    
    func showProgressView() {
        showProgressView_calledTimes += 1
    }
    
    func hideProgressView() {
        hideProgressView_calledTimes += 1
    }
    
    func warnDownloadIncomplete(downloadedCount: Int, failedCount: Int) async {
        warnDownloadIncompleteInvocations.append((downloadedCount, failedCount))
        onWarnDownloadIncomplete?()
    }
}
