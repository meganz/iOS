import MEGADomain
import MEGASdk

extension MEGAPaymentMethod {
    func toPaymentMethodEntity() -> PaymentMethodEntity {
        switch self {
        case .balance: return .balance
        case .paypal: return .paypal
        case .itunes: return .itunes
        case .googleWallet: return .googleWallet
        case .bitcoin: return .bitcoin
        case .unionPay: return .unionPay
        case .fortumo: return .fortumo
        case .stripe: return .stripe
        case .creditCard: return .creditCard
        case .centili: return .centili
        case .paysafeCard: return .paysafeCard
        case .astropay: return .astropay
        case .reserved: return .reserved
        case .windowsStore: return .windowsStore
        case .tpay: return .tpay
        case .directReseller: return .directReseller
        case .ECP: return .ECP
        case .sabadell: return .sabadell
        case .huaweiWallet: return .huaweiWallet
        case .stripe2: return .stripe2
        case .wireTransfer: return .wireTransfer
        @unknown default:
            return .none
        }
    }
}
