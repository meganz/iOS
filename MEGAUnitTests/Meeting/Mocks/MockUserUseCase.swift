@testable import MEGA

struct MockUserUseCase: UserUseCaseProtocol {
    let handle: UInt64
    var isLoggedIn: Bool
    var isGuest: Bool
    var userSDKEntity = UserSDKEntity(email: "", handle: 100, base64Handle: nil, change: nil, contact: nil)
    
    var myHandle: UInt64? {
        return handle
    }
    
    func user(withHandle handle: UInt64) -> UserSDKEntity? {
        guard userSDKEntity.handle == handle else { return nil }
        return userSDKEntity
    }
}
