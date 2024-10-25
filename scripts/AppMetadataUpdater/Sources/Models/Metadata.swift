import Foundation

struct Metadata: Codable {
    let name: String
    let id: String
    let filename: String
    let maxAllowedLength: Int?
    let maxAllowedOverflowError: String?
}
