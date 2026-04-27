import Foundation

struct ReleaseNotesMetadataUpdater: MetadataUpdating {
    let authorization: String
    let version: String?
    let baseURL: String
    let project: Project

    func convert(_ data: Data) throws -> [MetadataOutput] {
        let content = try ReleaseNotesConverter(data: data, version: version).toString()
        return [MetadataOutput(filename: project.filename, content: content, maxAllowedLength: project.maxAllowedLength)]
    }
}
