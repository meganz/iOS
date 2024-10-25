import Foundation

struct EnvironmentDetails: Codable {
    let fastlaneBasePath: String
    let projects: [Metadata]

    subscript(resourceId: MetadataResourceId) -> Metadata? {
        projects.first(where: { $0.name == resourceId.rawValue })
    }

    static func load() throws -> EnvironmentDetails {
        if let fileURL = Bundle.module.url(forResource: "environmentDetails", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(EnvironmentDetails.self, from: jsonData)
            } catch {
                throw "Error: \(error.localizedDescription)"
            }
        } else {
            throw "JSON file httpBody.json file not found"
        }
    }
}


