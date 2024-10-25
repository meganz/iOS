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

            return try await group.waitForAll()
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
