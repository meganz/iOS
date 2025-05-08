import MEGAAppSDKRepo
import MEGASdk

public final class MockMEGACurrency: MEGACurrency {
    public var _currencyName: String?
    public var _currencySymbol: String?
    public var _localCurrencyName: String?
    public var _localCurrencySymbol: String?

    public init(
        currencyName: String? = nil,
        currencySymbol: String? = nil,
        localCurrencyName: String? = nil,
        localCurrencySymbol: String? = nil
    ) {
        self._currencyName = currencyName
        self._currencySymbol = currencySymbol
        self._localCurrencyName = localCurrencyName
        self._localCurrencySymbol = localCurrencySymbol
    }

    public override var currencyName: String? {
        get { _currencyName }
        set { _currencyName = newValue }
    }

    public override var currencySymbol: String? {
        get { _currencySymbol }
        set { _currencySymbol = newValue }
    }

    public override var localCurrencyName: String? {
        get { _localCurrencyName }
        set { _localCurrencyName = newValue }
    }

    public override var localCurrencySymbol: String? {
        get { _localCurrencySymbol }
        set { _localCurrencySymbol = newValue }
    }
}
