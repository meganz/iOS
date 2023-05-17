import Foundation

class ServiceManager {
    
    // MARK: - Properties
    public static let shared: ServiceManager = ServiceManager()
    
    public var BASE_URL: String = "https://giphy.mega.nz/"
    
    public var GIPHY_URL = "giphy://"
}

// MARK: - Public Functions
extension ServiceManager {
    
    func sendRequest<T: Decodable>(request: RequestModel, completion: @escaping(Swift.Result<[T], ErrorModel>) -> Void) -> URLSessionDataTask {
        if request.isLoggingEnabled.0 {
            LogManager.req(request)
        }

       let task = URLSession.shared.dataTask(with: request.urlRequest()) { data, _, error in
            guard let data = data, var responseModel = try? JSONDecoder().decode(ResponseModel<T>.self, from: data) else {
                let error: ErrorModel = ErrorModel(ErrorKey.parsing.rawValue)
                LogManager.err(error)
                
                completion(Result.failure(error))
                return
            }
            
            responseModel.rawData = data
            responseModel.request = request
            
            if request.isLoggingEnabled.1 {
                LogManager.res(responseModel)
            }
            
            if responseModel.meta?.status == 200, let data = responseModel.data {
                completion(Result.success(data))
            } else {
                completion(Result.failure(ErrorModel.generalError()))
            }
            
        }
        task.resume()
        
        return task
    }
}
