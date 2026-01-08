import Foundation

struct Project: Codable {
    let name: String
    let component: String
    let filename: String
    let maxAllowedLength: Int?
    let maxAllowedOverflowError: String?
}
