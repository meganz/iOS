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
        mockRequest.megaSetHandle = sid
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func createSetElement(_ sid: MEGAHandle, nodeId: MEGAHandle, name: String?, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func updateSetElement(_ sid: MEGAHandle, eid: MEGAHandle, name: String, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetElementName = name
        mockRequest.updateSet = false
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func updateSetElementOrder(_ sid: MEGAHandle, eid: MEGAHandle, order: Int64, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetElementOrder = order
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func removeSetElement(_ sid: MEGAHandle, eid: MEGAHandle, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.updateSet = false
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
}
