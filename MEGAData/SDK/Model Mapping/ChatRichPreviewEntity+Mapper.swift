import MEGADomain

extension MEGAChatRichPreview {
    func toChatRichPreviewEntity() -> ChatRichPreviewEntity {
        ChatRichPreviewEntity(
            text: text ?? nil,
            title: title ?? nil,
            previewDescription: previewDescription ?? nil,
            image: image ?? nil,
            imageFormat: imageFormat ?? nil,
            icon: icon ?? nil,
            iconFormat: iconFormat ?? nil,
            url: url ?? nil
        )
    }
}

