public enum AlbumIdEntity: HandleEntity {
    case favourite = 0x01
    case gif = 0x02
    case raw = 0x03
    
    public var value: HandleEntity {
        self.rawValue
    }
}
