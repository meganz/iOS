import MEGADomain

extension TransferMetaDataEntity: @retroactive RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case ">exportFile": self = .exportFile
        case ">SaveInPhotosApp": self = .saveInPhotos
        default:
            return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .exportFile: return ">exportFile"
        case .saveInPhotos: return ">SaveInPhotosApp"
        }
    }
}
