import Foundation

struct MetadataOutput: Sendable {
    let filename: String
    let content: String
    let maxAllowedLength: Int?
}

protocol MetadataUpdater: Sendable {
    func updateMetadata() async throws
}

protocol MetadataUpdating: MetadataUpdater {
    var authorization: String { get }
    var baseURL: String { get }
    var project: Project { get }
    func convert(_ data: Data) throws -> [MetadataOutput]
}

extension MetadataUpdating {
    func updateMetadata() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for languageInfo in LanguageInfo.all {
                group.addTask {
                    try await updateMetadata(for: languageInfo)
                }
            }

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

        try Task.checkCancellation()

        do {
            let outputs = try convert(data)

            for output in outputs {
                if let max = output.maxAllowedLength, output.content.count > max {
                    print("Warning: \(output.filename) for \(languageInfo.name) exceeds \(max) chars (\(output.content.count))")
                    continue
                }

                let writer = Writer(
                    folders: languageInfo.fastlaneMetadataFolders,
                    languageName: languageInfo.name,
                    string: output.content,
                    fileName: output.filename
                )

                try writer.write()
            }
        } catch {
            print("""
                \n------------------\(languageInfo.name) Start -----------------
                Error converting: \(error.localizedDescription)
                ------------------\(languageInfo.name) End -----------------
                """)
        }
    }
}
