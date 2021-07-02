import Foundation

private enum RatingConstants {
    static let minimumTransferSpeedPerBytes = 2 * 1024 * 1024
    static let minimumTransferSizePerBytes = 10 * 1024 * 1024
    static let minimumShareCount = 5
}

protocol RatingRequestMoment { }

struct TransferMoment: RatingRequestMoment {
    let transfer: TransferEntity
}

struct ShareMoment: RatingRequestMoment {
    let shareUseCase: ShareUseCaseProtocol
}

struct RatingRequesting<M: RatingRequestMoment> {
    var shouldRequestRating: (M, RatingRequestBaseConditionsUseCaseProtocol) -> Bool
}

extension RatingRequesting where M == TransferMoment {
    static var transfer: RatingRequesting {
        return RatingRequesting { moment, baseCondition in
            moment.transfer.speed >= RatingConstants.minimumTransferSpeedPerBytes
                && moment.transfer.totalBytes >= RatingConstants.minimumTransferSizePerBytes
                 && baseCondition.hasMetBaseConditions()
        }
    }
}

extension RatingRequesting where M == ShareMoment {
    static var share: RatingRequesting {
        return RatingRequesting { moment, baseCondition in
            let publicLinkCount = moment.shareUseCase.allPublicLinks(sortBy: .none).count
            let outShareCount = moment.shareUseCase.allOutShares(sortBy: .none).count
            return baseCondition.hasMetBaseConditions()
                && publicLinkCount + outShareCount >= RatingConstants.minimumShareCount
        }
    }
}
