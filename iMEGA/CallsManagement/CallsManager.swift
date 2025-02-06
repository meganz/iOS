import MEGADomain
import MEGASwift

struct CallsManager: CallsManagerProtocol {
    static var shared = CallsManager()
    
    @Atomic private var callsDictionary = [UUID: CallActionSync]()

    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID? {
        callsDictionary.first(where: { $0.value.chatRoom == chatRoom })?.key
    }
    
    func call(forUUID uuid: UUID) -> CallActionSync? {
        callsDictionary[uuid]
    }
    
    func removeCall(withUUID uuid: UUID) {
        $callsDictionary.mutate {
            $0.removeValue(forKey: uuid)
        }
    }
    
    func removeAllCalls() {
        $callsDictionary.mutate {
            $0.removeAll()
        }
    }
    
    func updateCall(withUUID uuid: UUID, muted: Bool) {
        $callsDictionary.mutate {
            $0[uuid]?.audioEnabled = !muted
        }
    }
    
    func updateEndForAllCall(withUUID uuid: UUID) {
        $callsDictionary.mutate {
            $0[uuid]?.endForAll = true
        }
    }
    
    func addCall(_ call: CallActionSync, withUUID uuid: UUID) {
        $callsDictionary.mutate {
            $0[uuid] = call
        }
    }
}
