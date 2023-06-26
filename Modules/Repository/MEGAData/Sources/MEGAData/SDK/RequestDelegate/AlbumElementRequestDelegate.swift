import Foundation
import MEGASdk

typealias AlbumElementRequestCompletion = (_ result: Result<(UInt, UInt), MEGAError>) -> Void

final class AlbumElementRequestDelegate: NSObject, MEGARequestDelegate {
    let completion: AlbumElementRequestCompletion
    
    private var numberOfCalls = 0
    
    var succeedCount: UInt = 0
    var failedCount: UInt = 0
    
    init(numberOfCalls: Int, completion: @escaping AlbumElementRequestCompletion) {
        self.numberOfCalls = numberOfCalls
        self.completion = completion
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk {
            succeedCount += 1
        } else {
            failedCount += 1
        }
        
        if succeedCount + failedCount == numberOfCalls {
            completion(.success((succeedCount, failedCount)))
        }
    }
}
