import Foundation
import Yams

struct DescriptionConverter: Converting {
    let data: Data

    func toString() throws -> String {
        let description = try YAMLDecoder().decode(StoreMetadata.self, from: data)
        return try description.formattedString
    }
}
