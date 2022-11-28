import Foundation

final class AddPhotosToAlbumRequestDelegate: NSObject, MEGARequestDelegate {
    let completion: MEGARequestCompletion
    
    private var numberOfDuplicatedCalls = 0
    private var errorHappen = false
    private var count = 0
    
    init(numberOfCalls: Int, completion: @escaping MEGARequestCompletion) {
        self.numberOfDuplicatedCalls = numberOfCalls
        self.completion = completion
    }
    
    // Added count check to avoid completion called multiple times
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard !errorHappen else { return }
        
        if error.type == .apiOk {
            count += 1
            
            if count == numberOfDuplicatedCalls {
                self.completion(.success(request))
            }
        } else {
            errorHappen = true
            count = 0
            self.completion(.failure(error))
        }
    }
}
