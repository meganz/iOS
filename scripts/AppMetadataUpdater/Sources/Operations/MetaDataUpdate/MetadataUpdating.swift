import Foundation

protocol MetadataUpdating: Sendable {
    var authorization: String { get }
    var metadata: Metadata { get }
    func convert(_ data: Data) throws -> String
}

extension MetadataUpdating {
    func updateMetadata() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for languageInfo in LanguageInfo.all {
                group.addTask {
                    try await updateMetadata(for: languageInfo)
                }
            }

            // Complete when the first task throws an error or wait until all tasks have finished successfully
            while let _ = try await group.next() {}
        }
    }

    private func updateMetadata(for languageInfo: LanguageInfo) async throws {
        let api = try API(
            authorization: authorization,
            languageInfo: languageInfo,
            resourceDataId: metadata.id
        )
        let fetcher = Fetcher(api: api)
        let data = try await fetcher.fetch()
        // Now that data is fetched from the server, check if the task has been canceled before proceeding.
        try Task.checkCancellation()
        let string = try convert(data)
        if string.count > metadata.maxAllowedLength ?? -1, let errorString = metadata.maxAllowedOverflowError {
            throw errorString
        }
        let writer = Writer(
            folders: languageInfo.fastlaneMetadataFolders,
            languageName: languageInfo.name,
            string: string,
            fileName: metadata.filename
        )
        try writer.write()
    }
}
