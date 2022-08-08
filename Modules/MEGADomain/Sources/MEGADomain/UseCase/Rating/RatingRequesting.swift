import Foundation

private enum RatingConstants {
    static let minimumTransferSpeedPerBytes = 2 * 1024 * 1024
    static let minimumTransferSizePerBytes = 10 * 1024 * 1024
    static let minimumShareCount = 5
}

public protocol RatingRequestMoment { }

public struct TransferMoment: RatingRequestMoment {
    public let transfer: TransferEntity
    
    public init(transfer: TransferEntity) {
        self.transfer = transfer
    }
}

public struct ShareMoment: RatingRequestMoment {
    public let shareUseCase: ShareUseCaseProtocol
    
    public init(shareUseCase: ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
    }
}

public struct RatingRequesting<M: RatingRequestMoment> {
    public var shouldRequestRating: (M, RatingRequestBaseConditionsUseCaseProtocol) -> Bool
}

public extension RatingRequesting where M == TransferMoment {
    static var transfer: RatingRequesting {
        RatingRequesting { moment, baseCondition in
            moment.transfer.speed >= RatingConstants.minimumTransferSpeedPerBytes
                && moment.transfer.totalBytes >= RatingConstants.minimumTransferSizePerBytes
                 && baseCondition.hasMetBaseConditions()
        }
    }
}

public extension RatingRequesting where M == ShareMoment {
    static var share: RatingRequesting {
        RatingRequesting { moment, baseCondition in
            let publicLinkCount = moment.shareUseCase.allPublicLinks(sortBy: .none).count
            let outShareCount = moment.shareUseCase.allOutShares(sortBy: .none).count
            return baseCondition.hasMetBaseConditions()
                && publicLinkCount + outShareCount >= RatingConstants.minimumShareCount
        }
    }
}
