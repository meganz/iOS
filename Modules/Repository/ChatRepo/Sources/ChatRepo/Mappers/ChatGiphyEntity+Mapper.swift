import MEGAChatSdk
import MEGADomain

extension MEGAChatGiphy {
    func toChatGiphyEntity() -> ChatGiphyEntity {
        ChatGiphyEntity(
            mp4Src: mp4Src,
            webpSrc: webpSrc,
            mp4Size: mp4Size,
            webpSize: webpSize,
            title: title,
            width: width,
            height: height
        )
    }
}
