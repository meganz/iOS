import Foundation

public protocol CallLocalVideoRepositoryProtocol: RepositoryProtocol, Sendable {
    func enableLocalVideo(for chatId: HandleEntity) async throws
    func disableLocalVideo(for chatId: HandleEntity) async throws
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func addLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol)
    func removeLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, Error>) -> Void)
    func selectCamera(withLocalizedName localizedName: String) async throws
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
}

public protocol CallLocalVideoListenerRepositoryProtocol: AnyObject {
    func localVideoFrameData(width: Int, height: Int, buffer: Data)
    func localVideoChangedCameraPosition()
}
