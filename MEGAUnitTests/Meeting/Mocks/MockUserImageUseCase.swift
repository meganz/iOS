@testable import MEGA

struct MockUserImageUseCase: UserImageUseCaseProtocol {
    var result: Result<UIImage, UserImageLoadErrorEntity> = .failure(.generic)
    
    func fetchUserAvatar(withUserHandle handle: UInt64, name: String, completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        completion(result)
    }
}
