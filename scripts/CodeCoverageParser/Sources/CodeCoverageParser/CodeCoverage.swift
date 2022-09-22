import Foundation

struct CodeCoverage: Codable {
    let coverage: Double
    let targetCodeCoverages: [TargetCodeCoverage]
    
    enum CodingKeys: String, CodingKey {
        case coverage
        case targetCodeCoverages = "targets"
    }
}
