import UIKit

enum RequestHTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

class RequestModel: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    var path: String {
        return ""
    }
    var parameters: [String: Any?] {
        return [:]
    }
    var headers: [String: String] {
        return [:]
    }
    var method: RequestHTTPMethod {
        return body.isEmpty ? RequestHTTPMethod.get : RequestHTTPMethod.post
    }
    var body: [String: Any?] {
        return [:]
    }
    
    // (request, response)
    var isLoggingEnabled: (Bool, Bool) {
        return (true, true)
    }
}

// MARK: - Public Functions
extension RequestModel {
    
    func urlRequest() -> URLRequest {
        let endpoint: String = ServiceManager.shared.BASE_URL.appending(path)
        var urlComponents = URLComponents(string: endpoint)
        
        var queryItems = [URLQueryItem]()
        for parameter in parameters {
            if let value = parameter.value as? String {
                queryItems.append(URLQueryItem(name: parameter.key, value: value))
            }
        }
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            fatalError("invalid url")
        }
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        if method == RequestHTTPMethod.post {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.prettyPrinted)
            } catch let error {
                LogManager.e("Request body parse error: \(error.localizedDescription)")
            }
        }
        
        return request
    }
}
