import MEGADomain
import PushKit

final class VoIPPushDelegate: NSObject, PKPushRegistryDelegate {
    private weak var callsCoordinator: (any CallsCoordinatorProtocol)?
    private let voIpTokenUseCase: any VoIPTokenUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol

    init(callCoordinator: some CallsCoordinatorProtocol,
         voIpTokenUseCase: some VoIPTokenUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol) {
        self.callsCoordinator = callCoordinator
        self.voIpTokenUseCase = voIpTokenUseCase
        self.megaHandleUseCase = megaHandleUseCase
        super.init()
        
        registerForVoIPNotifications()
    }
    
    private func registerForVoIPNotifications() {
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([.voIP])
    }
    
    // MARK: - PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        
        guard pushCredentials.token.count > 0 else {
            MEGALogError("VoIP token length is 0")
            return
        }
        
        let dataBuffer = [UInt8](pushCredentials.token)
        let hexString = dataBuffer.map { String(format: "%02x", $0) }.joined()
        
        let deviceTokenString = String(hexString)
        MEGALogDebug("Device token \(deviceTokenString)")
        voIpTokenUseCase.registerVoIPDeviceToken(deviceTokenString)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        MEGALogDebug("Did receive incoming push with payload: \(payload.dictionaryPayload), and type: \(type)")
        
        if isVoIPPush(for: payload) {
            guard let chatId = chatId(from: payload) else { return }
            callsCoordinator?.reportIncomingCall(in: chatId, completion: completion)
        }
    }
    
    // MARK: - Private
    private func isVoIPPush(for payload: PKPushPayload) -> Bool {
        guard let megaType = payload.dictionaryPayload["megatype"] as? Int else {
            return false
        }
        return megaType == 4
    }
    
    private func chatId(from payload: PKPushPayload) -> ChatIdEntity? {
        guard let megaData = payload.dictionaryPayload["megadata"] as? [String: Any],
           let chatIdB64 = megaData["chatid"] as? String else {
            return nil
        }
        
        return megaHandleUseCase.handle(forBase64UserHandle: chatIdB64)
    }
}
