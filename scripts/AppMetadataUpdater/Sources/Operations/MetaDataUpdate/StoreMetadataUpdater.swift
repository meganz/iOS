import Foundation

struct StoreMetadataUpdater: MetadataUpdating {
    let authorization: String
    let baseURL: String
    let project: Project

    func convert(_ data: Data) throws -> [MetadataOutput] {
        try StoreMetadataConverter(data: data).toOutputs()
    }
}
