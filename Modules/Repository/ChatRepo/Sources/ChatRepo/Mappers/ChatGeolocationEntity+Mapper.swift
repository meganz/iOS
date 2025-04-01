import MEGAChatSdk
import MEGADomain

extension MEGAChatGeolocation {
    func toChatGeolocationEntity() -> ChatGeolocationEntity {
        ChatGeolocationEntity(longitude: longitude, latitude: latitude, image: image)
    }
}
