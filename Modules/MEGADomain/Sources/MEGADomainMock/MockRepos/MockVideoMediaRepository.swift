import MEGADomain

public struct MockVideoMediaRepository: VideoMediaRepositoryProtocol {
    public static var newRepo: MockVideoMediaRepository {
        MockVideoMediaRepository()
    }
    
    let supportedFormats: [ShortFormatEntity]
    let supportedCodecs: [CodecIdEntity]
    
    public init(supportedFormats: [ShortFormatEntity] = [], supportedCodecs: [CodecIdEntity] = []) {
        self.supportedFormats = supportedFormats
        self.supportedCodecs = supportedCodecs
    }
    
    public func isSupportedFormat(_ shortFormat: ShortFormatEntity) -> Bool {
        supportedFormats.contains(shortFormat)
    }
    
    public func isSupportedCodec(_ codecId: CodecIdEntity) -> Bool {
        supportedCodecs.contains(codecId)
    }
}
