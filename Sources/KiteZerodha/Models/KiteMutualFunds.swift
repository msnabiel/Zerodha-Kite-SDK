import Foundation

public struct KiteMFOrder: Sendable, Codable {
    public let orderID: String?
    public let exchangeOrderID: String?
    public let tradingsymbol: String?
    public let status: String?
    public let statusMessage: String?
    public let folio: String?
    public let fund: String?
    public let orderTimestamp: String?
    public let exchangeTimestamp: String?
    public let settlementID: String?
    public let transactionType: String?
    public let variety: String?
    public let purchaseType: String?
    public let quantity: Double?
    public let amount: Double?
    public let averagePrice: Double?
    public let placedBy: String?
    public let tag: String?

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case exchangeOrderID = "exchange_order_id"
        case tradingsymbol, status, folio, fund, quantity, amount, tag
        case statusMessage = "status_message"
        case orderTimestamp = "order_timestamp"
        case exchangeTimestamp = "exchange_timestamp"
        case settlementID = "settlement_id"
        case transactionType = "transaction_type"
        case variety
        case purchaseType = "purchase_type"
        case averagePrice = "average_price"
        case placedBy = "placed_by"
    }
}

public struct KiteMFSIP: Sendable, Codable {
    public let sipID: String?
    public let tradingsymbol: String?
    public let fundName: String?
    public let fundSource: String?
    public let dividendType: String?
    public let transactionType: String?
    public let status: String?
    public let created: String?
    public let frequency: String?
    public let instalmentAmount: Double?
    public let instalments: Int?
    public let lastInstalment: String?
    public let pendingInstalments: Int?
    public let instalmentDay: Int?
    public let completedInstalments: Int?
    public let nextInstalment: String?
    public let tag: String?
    public let stepUp: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case sipID = "sip_id"
        case tradingsymbol, status, created, frequency, instalments, tag
        case fundName = "fund"
        case fundSource = "fund_source"
        case dividendType = "dividend_type"
        case transactionType = "transaction_type"
        case instalmentAmount = "instalment_amount"
        case lastInstalment = "last_instalment"
        case pendingInstalments = "pending_instalments"
        case instalmentDay = "instalment_day"
        case completedInstalments = "completed_instalments"
        case nextInstalment = "next_instalment"
        case stepUp = "step_up"
    }
}

public struct KiteMFHolding: Sendable, Codable {
    public let folio: String?
    public let tradingsymbol: String?
    public let fund: String?
    public let averagePrice: Double?
    public let lastPrice: Double?
    public let lastPriceDate: String?
    public let quantity: Double?
    public let pnl: Double?
    public let pledgedQuantity: Double?

    enum CodingKeys: String, CodingKey {
        case folio, tradingsymbol, fund, quantity, pnl
        case averagePrice = "average_price"
        case lastPrice = "last_price"
        case lastPriceDate = "last_price_date"
        case pledgedQuantity = "pledged_quantity"
    }
}

