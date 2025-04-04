import MEGADomain

public final class VideoMediaRepository: VideoMediaRepositoryProtocol {
    public static var newRepo: VideoMediaRepository {
        VideoMediaRepository()
    }
    
    private let shortFormats = [-1, 1, 2, 3, 4, 5, 13, 27, 44, 49, 50, 51, 52]
    private let codecIds = [-1, 15, 37, 144, 215, 224, 266, 346, 348, 393, 405, 523, 532, 551, 630, 703, 740, 802, 887, 957, 961, 973, 1108, 1114, 1119, 1129, 1132, 1177]
    
    public init() {}
    
    public func isSupportedFormat(_ shortFormat: ShortFormatEntity) -> Bool {
        shortFormats.contains(shortFormat)
    }
    
    public func isSupportedCodec(_ codecId: CodecIdEntity) -> Bool {
        codecIds.contains(codecId)
    }
}
