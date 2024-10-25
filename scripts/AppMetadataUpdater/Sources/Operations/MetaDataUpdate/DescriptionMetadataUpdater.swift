import Foundation

struct DescriptionMetadataUpdater: MetadataUpdating {
    let authorization: String
    let metadata: Metadata

    func convert(_ data: Data) throws -> String {
        try DescriptionConverter(data: data).toString()
    }

    func verify(_ string: String) throws {
        guard string.count <= 4000 else {
            throw "The app description is too long. Should be lesser than 4000 characters"
        }
    }
}
