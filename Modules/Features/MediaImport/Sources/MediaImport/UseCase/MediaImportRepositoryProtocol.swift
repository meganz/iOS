import Foundation

public protocol MediaImportRepositoryProtocol: Sendable {
    /// Loads the file representation for the given item provider, copies it
    /// to a sandbox location, and reports byte-level loading progress.
    ///
    /// - Parameters:
    ///   - itemProvider: The item provider to load the file from.
    ///   - progressHandler: Called with fractionCompleted (0.0-1.0) as bytes load.
    /// - Returns: The staged file URL, relative to the app container.
    func loadAndStageItem(
        from itemProvider: NSItemProvider,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL
}
