import Foundation

struct HttpBody: Codable {
    var data: ResourceData

    static func loadEnglish() throws -> Self {
        if let fileURL = Bundle.module.url(forResource: "httpBodyEnglish", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(HttpBody.self, from: jsonData)
            } catch {
                throw "Error: \(error.localizedDescription)"
            }
        } else {
            throw "JSON file httpBody.json file not found"
        }

    }

    static func loadOthers() throws -> Self {
        if let fileURL = Bundle.module.url(forResource: "httpBodyOthers", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(HttpBody.self, from: jsonData)
            } catch {
                throw "Error: \(error.localizedDescription)"
            }
        } else {
            throw "JSON file httpBody.json file not found"
        }
    }
    
    func toJSON() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(self)
        guard let jsonData = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] else {
            throw "Cannot convert model to JSON data"
        }
        return jsonData
    }
}
