import Foundation

struct ReleaseNotesMetadataUpdater: MetadataUpdating {
    let authorization: String
    let version: String?
    let baseURL: String
    let project: Project

    func convert(_ data: Data) throws -> String {
        try ReleaseNotesConverter(data: data, version: version).toString()
    }
}
