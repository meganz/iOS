import Foundation

public enum HTTPError: Error {
    case badResponse
    case cannotParseBody
    case cannotDecodeContentData
    case cannotParseResponse
    case badURL
    case invalidURL(String)
}

public enum HTTPMethod: String {
    case post = "POST"
    case get = "GET"
    case put = "PUT"
}

public struct HTTPHeader {
    public let field: String
    public let value: String

    public init(field: String, value: String) {
        self.field = field
        self.value = value
    }
}

public enum HTTPToken {
    case bearer(String)
    case other(HTTPHeader)
}

@discardableResult
public func sendRequest(
    url: URL,
    method: HTTPMethod,
    token: HTTPToken? = nil,
    headers: [HTTPHeader] = [],
    body: [String: Any]? = nil
) async throws -> Data {
    let request = try makeURLRequest(url: url, method: method, token: token, headers: headers, body: body)

    if verbose {
        print(
        """
        Sending request:
            - URL: \(url.absoluteString)
            - HTTP method: \(method.rawValue)
            - token: \(String(describing: token))
            - headers: \(String(describing: headers))
            - body: \(String(describing: body))
        """
        )
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPError.cannotParseResponse
    }

    let httpOk = 200...299

    guard httpOk.contains(httpResponse.statusCode) else {
        print("Bad status code: \(httpResponse.statusCode)")
        throw HTTPError.badResponse
    }

    if verbose {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw HTTPError.cannotDecodeContentData
        }

        print("Response:\n\(jsonString)")
    }

    return data
}

private func makeURLRequest(
    url: URL,
    method: HTTPMethod,
    token: HTTPToken?,
    headers: [HTTPHeader],
    body: [String: Any]?
) throws -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue

    switch token {
    case .bearer(let base64Token):
        request.addValue("Bearer \(base64Token)", forHTTPHeaderField: "Authorization")
    case .other(let authHeader):
        request.addValue(authHeader.value, forHTTPHeaderField: authHeader.field)
    case .none:
        break
    }

    for header in headers {
        request.addValue(header.value, forHTTPHeaderField: header.field)
    }

    if let body {
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            throw HTTPError.cannotParseBody
        }

        request.httpBody = httpBody
    }

    return request
}

public func makeURL(base: URL, path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
    var components = URLComponents(url: base, resolvingAgainstBaseURL: true)
    components?.path = path

    if let queryItems = queryItems, !queryItems.isEmpty {
        components?.queryItems = queryItems
    }

    guard let components, let url = components.url else {
        throw HTTPError.badURL
    }

    return url
}

public func makeURL(string: String) throws -> URL {
    guard let url = URL(string: string) else {
        throw HTTPError.invalidURL(string)
    }

    return url
}

public let iso8601Formatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter
}()
