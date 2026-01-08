import Foundation

protocol MetadataUpdating: Sendable {
    var authorization: String { get }
    var baseURL: String { get }
    var project: Project { get }
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
            baseURL: baseURL,
            authorization: authorization,
            languageCode: languageInfo.code,
            project: project
        )
        
        let fetcher = Fetcher(api: api)
        let data = try await fetcher.fetch()

        // Now that data is fetched from the server, check if the task has been canceled before proceeding.
        try Task.checkCancellation()
        do {
            let string = try convert(data)

            if string.count > project.maxAllowedLength ?? -1, let errorString = project.maxAllowedOverflowError {
                throw errorString
            }

            let writer = Writer(
                folders: languageInfo.fastlaneMetadataFolders,
                languageName: languageInfo.name,
                string: string,
                fileName: project.filename
            )

            try writer.write()
        } catch {
            print("""
                \n------------------\(languageInfo.name) Start -----------------
                Error converting: \(error.localizedDescription)
                ------------------\(languageInfo.name) End -----------------
                """)
        }
    }
}
