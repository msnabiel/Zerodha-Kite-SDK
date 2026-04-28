import Foundation

public struct KiteMarginOrderRequest: Sendable, Codable {
    public let exchange: String
    public let tradingsymbol: String
    public let transactionType: String
    public let variety: String
    public let product: String
    public let orderType: String
    public let quantity: Int
    public let price: Double
    public let triggerPrice: Double

    enum CodingKeys: String, CodingKey {
        case exchange, tradingsymbol, quantity, price
        case transactionType = "transaction_type"
        case variety, product
        case orderType = "order_type"
        case triggerPrice = "trigger_price"
    }
}

public struct KiteMarginChargesGST: Sendable, Codable { public let igst: Double?; public let cgst: Double?; public let sgst: Double?; public let total: Double? }
public struct KiteMarginCharges: Sendable, Codable {
    public let total: Double?
    public let transactionTax: Double?
    public let transactionTaxType: String?
    public let exchangeTurnoverCharge: Double?
    public let sebiTurnoverCharge: Double?
    public let brokerage: Double?
    public let stampDuty: Double?
    public let gst: KiteMarginChargesGST?
    enum CodingKeys: String, CodingKey {
        case total, brokerage, gst
        case transactionTax = "transaction_tax"
        case transactionTaxType = "transaction_tax_type"
        case exchangeTurnoverCharge = "exchange_turnover_charge"
        case sebiTurnoverCharge = "sebi_turnover_charge"
        case stampDuty = "stamp_duty"
    }
}

public struct KiteMarginPNL: Sendable, Codable { public let realised: Double?; public let unrealised: Double? }
public struct KiteMarginResult: Sendable, Codable {
    public let type: String?
    public let tradingsymbol: String?
    public let exchange: String?
    public let span: Double?
    public let exposure: Double?
    public let optionPremium: Double?
    public let additional: Double?
    public let bo: Double?
    public let cash: Double?
    public let `var`: Double?
    public let pnl: KiteMarginPNL?
    public let leverage: Double?
    public let charges: KiteMarginCharges?
    public let total: Double?

    enum CodingKeys: String, CodingKey {
        case type, tradingsymbol, exchange, span, exposure, additional, bo, cash, pnl, leverage, charges, total
        case optionPremium = "option_premium"
        case `var` = "var"
    }
}

public struct KiteChargesOrderRequest: Sendable, Codable {
    public let orderID: String
    public let exchange: String
    public let tradingsymbol: String
    public let transactionType: String
    public let variety: String
    public let product: String
    public let orderType: String
    public let quantity: Int
    public let averagePrice: Double
    enum CodingKeys: String, CodingKey {
        case orderID = "order_id", exchange, tradingsymbol, variety, product, quantity
        case transactionType = "transaction_type"
        case orderType = "order_type"
        case averagePrice = "average_price"
    }
}

