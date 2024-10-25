import Foundation
import SharedReleaseScript

struct API {
    let url: URL
    let body: HttpBody
    let headers: [HTTPHeader]

    init(authorization: String, languageInfo: LanguageInfo, resourceDataId: String) throws {
        let languageDetails = LanguageDetails(languageInfo: languageInfo)
        url = languageDetails.url

        var body = try languageDetails.httpBody()
        body.data.relationships.resource.data.id = resourceDataId
        body.data.relationships.language?.data.id = languageInfo.transifexCode
        self.body = body

        var headers: [HTTPHeader] = []
        if authorization.contains("Bearer ") {
            headers.append(HTTPHeader(field: "Authorization", value: authorization))
        } else {
            headers.append(HTTPHeader(field: "Authorization", value: "Bearer \(authorization)"))
        }

        headers += [
            HTTPHeader(field: "accept", value: "*/*"),
            HTTPHeader(field: "content-type", value: "application/vnd.api+json")
        ]

        self.headers = headers
    }
}
