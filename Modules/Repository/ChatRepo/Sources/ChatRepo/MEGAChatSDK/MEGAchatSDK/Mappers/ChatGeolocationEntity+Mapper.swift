import MEGADomain
import MEGAChatSdk

extension MEGAChatGeolocation {
    func toChatGeolocationEntity() -> ChatGeolocationEntity {
        ChatGeolocationEntity(longitude: longitude, latitude: latitude, image: image)
    }
}
