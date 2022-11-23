import Foundation
@testable import MEGA
import MEGADomain

extension MockSdk {
    override func megaSets() -> [MEGASet] {
        sets
    }
    
    override func megaSetElements(bySid sid: MEGAHandle) -> [MEGASetElement] {
        setElements
    }
    
    override func createSet(_ name: String?, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSet = MockMEGASet(handle: 1, userId: 0, coverId: 1, name: name ?? "")
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func updateSetName(_ sid: MEGAHandle, name: String, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetName = name
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func removeSet(_ sid: MEGAHandle, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.magaSetHandle = sid
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
}
