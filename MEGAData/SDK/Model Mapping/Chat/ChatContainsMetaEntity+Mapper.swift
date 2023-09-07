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
