@testable import MEGA

struct MockUserImageUseCase: UserImageUseCaseProtocol {
    var result: Result<UIImage, UserImageLoadError> = .failure(.generic)
    
    func fetchUserAvatar(withUserHandle handle: UInt64, name: String, completion: @escaping (Result<UIImage, UserImageLoadError>) -> Void) {
        completion(result)
    }
}
