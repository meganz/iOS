import MEGADomain

extension MEGAChatContainsMeta {
    func toChatContainsMetaEntity() -> ChatContainsMetaEntity {
        ChatContainsMetaEntity(
            type: type.toMetaType(),
            textMessage: textMessage,
            richPreview: richPreview?.toChatRichPreviewEntity(),
            geoLocation: geolocation?.toChatGeolocationEntity(),
            giphy: giphy?.toChatGiphyEntity()
        )
    }
}

extension MEGAChatContainsMetaType {
    func toMetaType() -> ChatContainsMetaEntity.MetaType? {
        switch self {
        case .invalid:
            return .invalid
        case .richPreview:
            return .richPreview
        case .geolocation:
            return .geolocation
        case .giphy:
            return .giphy
        @unknown default:
            return nil
        }
    }
}
