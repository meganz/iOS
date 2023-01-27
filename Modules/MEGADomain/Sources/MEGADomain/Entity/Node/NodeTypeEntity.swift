public enum NodeTypeEntity: Int, Sendable {
    case unknown    = -1
    case file       = 0
    case folder
    case root
    case incoming
    case rubbish
}
