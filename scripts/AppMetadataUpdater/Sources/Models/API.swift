import Foundation
import SharedReleaseScript

struct API {
    let url: URL
    let headers: [HTTPHeader]

    init(baseURL: String, authorization: String, languageCode: String, project: Project) throws {
        guard let url = URL(
            string: "\(baseURL)/\(project.name)/\(project.component)/\(languageCode)/file/"
        ) else {
            throw "Invalid API URL"
        }

        self.url = url

        var headers: [HTTPHeader] = []
        if authorization.contains("Token ") {
            headers.append(HTTPHeader(field: "Authorization", value: authorization))
        } else {
            headers.append(HTTPHeader(field: "Authorization", value: "Token \(authorization)"))
        }

        headers += [
            HTTPHeader(field: "accept", value: "*/*"),
            HTTPHeader(field: "content-type", value: "application/json")
        ]

        self.headers = headers
    }
}
