
public protocol VideoMediaRepositoryProtocol: RepositoryProtocol {
    func isSupportedFormat(_ shortFormat: ShortFormatEntity) -> Bool
    func isSupportedCodec(_ codecId: CodecIdEntity) -> Bool
}
