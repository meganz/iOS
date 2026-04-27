import Foundation

struct DescriptionMetadataUpdater: MetadataUpdating {
    let authorization: String
    let baseURL: String
    let project: Project

    func convert(_ data: Data) throws -> [MetadataOutput] {
        let content = try DescriptionConverter(data: data).toString()
        return [MetadataOutput(filename: project.filename, content: content, maxAllowedLength: project.maxAllowedLength)]
    }
}
