import Foundation
import MEGADomain
import MEGASdk

typealias ThumbnailRequestCompletion = (_ result: Result<URL, any Error>) -> Void

final class ThumbnailRequestDelegate: NSObject, MEGARequestDelegate {
    private let completion: ThumbnailRequestCompletion
    
    init(completion: @escaping ThumbnailRequestCompletion) {
        self.completion = completion
        super.init()
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk {
            if let url = request.toFileURL() {
                completion(.success(url))
            } else {
                completion(.failure(GenericErrorEntity()))
            }
        } else {
            switch error.type {
            case .apiENoent:
                completion(.failure(ThumbnailErrorEntity.noThumbnail(.thumbnail)))
            default:
                completion(.failure(GenericErrorEntity()))
            }
        }
    }
}
