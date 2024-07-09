import MEGADomain
import PushKit

@objc final class VoIPPushDelegate: NSObject, PKPushRegistryDelegate {
    private weak var callsCoordinator: (any CallsCoordinatorProtocol)?
    private let voIpTokenUseCase: any VoIPTokenUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private var voIPPushRegistry: PKPushRegistry?
    private let logger: (String) -> Void
    init(
        callCoordinator: some CallsCoordinatorProtocol,
        voIpTokenUseCase: some VoIPTokenUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        logger: @escaping (String) -> Void
    ) {
        self.callsCoordinator = callCoordinator
        self.voIpTokenUseCase = voIpTokenUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.logger = logger
        super.init()
        
        registerForVoIPNotifications()
        logger("[VoIPPushDelegate] init")
    }
    
    private func registerForVoIPNotifications() {
        logger("[VoIPPushDelegate] register for voIP notifications")
        voIPPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voIPPushRegistry?.delegate = self
        voIPPushRegistry?.desiredPushTypes = Set([.voIP])
    }
    
    deinit {
        logger("[VoIPPushDelegate] deinit")
    }
    
    // MARK: - PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        logger("[VoIPPushDelegate] did update credentials")
        guard type == .voIP else {
            return
        }
        
        guard pushCredentials.token.count > 0 else {
            logger("VoIP token length is 0")
            return
        }
        
        let dataBuffer = [UInt8](pushCredentials.token)
        let hexString = dataBuffer.map { String(format: "%02x", $0) }.joined()
        
        let deviceTokenString = String(hexString)
        logger("Device token \(deviceTokenString)")
        voIpTokenUseCase.registerVoIPDeviceToken(deviceTokenString)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        logger("[VoIPPushDelegate] Did receive incoming push with payload: \(payload.dictionaryPayload), and type: \(type)")
        guard let callsCoordinator else {
            logger("[VoIPPushDelegate] missing callsCoordinator")
            return
        }
        
        guard let chatId = chatId(from: payload) else {
            logger("[VoIPPushDelegate] missing chat id")
            return
        }
        
        if isVoIPPush(for: payload) {
            logger("[VoIPPushDelegate] correct type of payload")
            callsCoordinator.reportIncomingCall(in: chatId, completion: completion)
        } else {
            logger("[VoIPPushDelegate] wrong type of payload")
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
