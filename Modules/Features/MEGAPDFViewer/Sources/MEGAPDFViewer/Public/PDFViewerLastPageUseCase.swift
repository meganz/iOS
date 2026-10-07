import Foundation

public protocol PDFViewerLastPageUseCaseProtocol: Sendable {
    func documentIdentifierForLastViewedPageIndex(forDocumentAt url: URL) async -> String?

    /// The 0-based page to resume at, or nil if there is nothing to resume.
    func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int?

    /// Persists the 0-based last-viewed page for `documentIdentifier`.
    /// - Clears the stored page when `index` is `0` or less.
    func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async
}

public struct PDFViewerLastPageUseCase: PDFViewerLastPageUseCaseProtocol {
    private let repository: any PDFViewerLastPageRepositoryProtocol
    private let fingerprintRepository: any PDFViewerDocumentFingerprintRepositoryProtocol

    public init(
        repository: some PDFViewerLastPageRepositoryProtocol,
        fingerprintRepository: some PDFViewerDocumentFingerprintRepositoryProtocol
    ) {
        self.repository = repository
        self.fingerprintRepository = fingerprintRepository
    }

    public func documentIdentifierForLastViewedPageIndex(forDocumentAt url: URL) async -> String? {
        let fingerprint = await fingerprintRepository.fingerprint(forFileAt: url)
        // Follow legacy viewer - empty string is treated equally to `nil`.
        return fingerprint?.isEmpty == false ? fingerprint : nil
    }

    public func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int? {
        await repository.loadLastPageIndex(forDocumentIdentifier: documentIdentifier)
    }

    public func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async {
        if index <= 0 {
            await repository.deleteLastPageIndex(forDocumentIdentifier: documentIdentifier)
        } else {
            await repository.saveLastPageIndex(index, forDocumentIdentifier: documentIdentifier)
        }
    }
}
