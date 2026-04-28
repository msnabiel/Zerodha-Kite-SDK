import Foundation

public enum AnyCodable: Sendable, Codable {
    case string(String), int(Int), double(Double), bool(Bool), array([AnyCodable]), object([String: AnyCodable]), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Int.self) { self = .int(v) }
        else if let v = try? c.decode(Double.self) { self = .double(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([AnyCodable].self) { self = .array(v) }
        else if let v = try? c.decode([String: AnyCodable].self) { self = .object(v) }
        else { throw DecodingError.typeMismatch(AnyCodable.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported type")) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }
}

public struct KiteSessionMeta: Sendable, Codable {
    public let dematConsent: String?
    enum CodingKeys: String, CodingKey {
        case dematConsent = "demat_consent"
    }
}

public struct KiteSession: Sendable, Codable {
    public let userID: String?
    public let userName: String?
    public let userShortname: String?
    public let email: String?
    public let userType: String?
    public let broker: String?
    public let exchanges: [String]?
    public let products: [String]?
    public let orderTypes: [String]?
    public let avatarURL: String?
    public let apiKey: String?
    public let accessToken: String
    public let publicToken: String?
    public let refreshToken: String?
    public let enctoken: String?
    public let loginTime: String?
    public let meta: KiteSessionMeta?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userName = "user_name"
        case userShortname = "user_shortname"
        case email
        case userType = "user_type"
        case broker, exchanges, products
        case orderTypes = "order_types"
        case avatarURL = "avatar_url"
        case apiKey = "api_key"
        case accessToken = "access_token"
        case publicToken = "public_token"
        case refreshToken = "refresh_token"
        case enctoken
        case loginTime = "login_time"
        case meta
    }
}

public struct KiteOrder: Sendable, Codable {
    public let orderID: String
    public let exchangeOrderID: String?
    public let parentOrderID: String?
    public let status: String?
    public let statusMessage: String?
    public let statusMessageRaw: String?
    public let exchange: String?
    public let tradingsymbol: String?
    public let transactionType: String?
    public let orderType: String?
    public let product: String?
    public let variety: String?
    public let validity: String?
    public let validityTTL: Int?
    public let quantity: Int?
    public let disclosedQuantity: Int?
    public let filledQuantity: Int?
    public let pendingQuantity: Int?
    public let cancelledQuantity: Int?
    public let price: Double?
    public let triggerPrice: Double?
    public let averagePrice: Double?
    public let tag: String?
    public let marketProtection: Int?
    public let icebergLegs: Int?
    public let icebergQuantity: Int?
    public let auctionNumber: Int?
    public let orderTimestamp: String?
    public let exchangeTimestamp: String?
    public let exchangeUpdateTimestamp: String?
    public let placedBy: String?
    public let guid: String?
    public let meta: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case exchangeOrderID = "exchange_order_id"
        case parentOrderID = "parent_order_id"
        case status
        case statusMessage = "status_message"
        case statusMessageRaw = "status_message_raw"
        case exchange, tradingsymbol, product, quantity, price, variety, validity, tag, guid, meta
        case transactionType = "transaction_type"
        case orderType = "order_type"
        case disclosedQuantity = "disclosed_quantity"
        case filledQuantity = "filled_quantity"
        case pendingQuantity = "pending_quantity"
        case cancelledQuantity = "cancelled_quantity"
        case triggerPrice = "trigger_price"
        case averagePrice = "average_price"
        case validityTTL = "validity_ttl"
        case marketProtection = "market_protection"
        case icebergLegs = "iceberg_legs"
        case icebergQuantity = "iceberg_quantity"
        case auctionNumber = "auction_number"
        case orderTimestamp = "order_timestamp"
        case exchangeTimestamp = "exchange_timestamp"
        case exchangeUpdateTimestamp = "exchange_update_timestamp"
        case placedBy = "placed_by"
    }
}

public struct KiteTrade: Sendable, Codable {
    public let tradeID: String?
    public let orderID: String?
    public let exchangeOrderID: String?
    public let tradingsymbol: String?
    public let exchange: String?
    public let instrumentToken: UInt32?
    public let transactionType: String?
    public let product: String?
    public let averagePrice: Double?
    public let quantity: Int?
    public let fillTimestamp: String?
    public let exchangeTimestamp: String?

    enum CodingKeys: String, CodingKey {
        case tradeID = "trade_id"
        case orderID = "order_id"
        case exchangeOrderID = "exchange_order_id"
        case tradingsymbol, exchange, product, quantity
        case instrumentToken = "instrument_token"
        case transactionType = "transaction_type"
        case averagePrice = "average_price"
        case fillTimestamp = "fill_timestamp"
        case exchangeTimestamp = "exchange_timestamp"
    }
}

public struct KiteOHLCData: Sendable, Codable { public let open, high, low, close: Double? }
public struct KiteDepthLevel: Sendable, Codable { public let quantity: Int?; public let price: Double?; public let orders: Int? }
public struct KiteDepth: Sendable, Codable { public let buy: [KiteDepthLevel]?; public let sell: [KiteDepthLevel]? }

public struct KiteLTPQuote: Sendable, Codable {
    public let instrumentToken: UInt32?
    public let lastPrice: Double?
    enum CodingKeys: String, CodingKey { case instrumentToken = "instrument_token", lastPrice = "last_price" }
}
public struct KiteOHLCQuote: Sendable, Codable {
    public let instrumentToken: UInt32?
    public let lastPrice: Double?
    public let ohlc: KiteOHLCData?
    enum CodingKeys: String, CodingKey { case instrumentToken = "instrument_token", lastPrice = "last_price", ohlc }
}
public struct KiteFullQuote: Sendable, Codable {
    public let instrumentToken: UInt32?
    public let timestamp: String?
    public let lastTradeTime: String?
    public let lastPrice: Double?
    public let lastQuantity: Int?
    public let averagePrice: Double?
    public let volume: Int?
    public let buyQuantity: Int?
    public let sellQuantity: Int?
    public let openInterest: Int?
    public let oiDayHigh: Int?
    public let oiDayLow: Int?
    public let netChange: Double?
    public let lowerCircuitLimit: Double?
    public let upperCircuitLimit: Double?
    public let ohlc: KiteOHLCData?
    public let depth: KiteDepth?

    enum CodingKeys: String, CodingKey {
        case instrumentToken = "instrument_token"
        case timestamp
        case lastTradeTime = "last_trade_time"
        case lastPrice = "last_price"
        case lastQuantity = "last_quantity"
        case averagePrice = "average_price"
        case volume, ohlc, depth
        case buyQuantity = "buy_quantity"
        case sellQuantity = "sell_quantity"
        case openInterest = "oi"
        case oiDayHigh = "oi_day_high"
        case oiDayLow = "oi_day_low"
        case netChange = "net_change"
        case lowerCircuitLimit = "lower_circuit_limit"
        case upperCircuitLimit = "upper_circuit_limit"
    }
}

public struct KitePosition: Sendable, Codable {
    public let tradingsymbol: String?
    public let exchange: String?
    public let instrumentToken: UInt32?
    public let product: String?
    public let quantity: Int?
    public let overnightQuantity: Int?
    public let multiplier: Double?
    public let averagePrice: Double?
    public let closePrice: Double?
    public let lastPrice: Double?
    public let value: Double?
    public let pnl: Double?
    public let m2m: Double?
    public let unrealised: Double?
    public let realised: Double?
    public let buyQuantity: Int?
    public let buyPrice: Double?
    public let buyValue: Double?
    public let buyM2M: Double?
    public let sellQuantity: Int?
    public let sellPrice: Double?
    public let sellValue: Double?
    public let sellM2M: Double?
    public let dayBuyQuantity: Int?
    public let dayBuyPrice: Double?
    public let dayBuyValue: Double?
    public let daySellQuantity: Int?
    public let daySellPrice: Double?
    public let daySellValue: Double?

    enum CodingKeys: String, CodingKey {
        case tradingsymbol, exchange, product, quantity, multiplier, value, pnl, m2m, unrealised, realised
        case instrumentToken = "instrument_token"
        case overnightQuantity = "overnight_quantity"
        case averagePrice = "average_price"
        case closePrice = "close_price"
        case lastPrice = "last_price"
        case buyQuantity = "buy_quantity"
        case buyPrice = "buy_price"
        case buyValue = "buy_value"
        case buyM2M = "buy_m2m"
        case sellQuantity = "sell_quantity"
        case sellPrice = "sell_price"
        case sellValue = "sell_value"
        case sellM2M = "sell_m2m"
        case dayBuyQuantity = "day_buy_quantity"
        case dayBuyPrice = "day_buy_price"
        case dayBuyValue = "day_buy_value"
        case daySellQuantity = "day_sell_quantity"
        case daySellPrice = "day_sell_price"
        case daySellValue = "day_sell_value"
    }
}

public struct KiteHolding: Sendable, Codable {
    public let tradingsymbol: String?
    public let exchange: String?
    public let instrumentToken: UInt32?
    public let isin: String?
    public let product: String?
    public let price: Double?
    public let quantity: Int?
    public let t1Quantity: Int?
    public let realisedQuantity: Int?
    public let authorisedQuantity: Int?
    public let authorisedDate: String?
    public let openingQuantity: Int?
    public let collateralQuantity: Int?
    public let collateralType: String?
    public let discrepancy: Bool?
    public let averagePrice: Double?
    public let lastPrice: Double?
    public let closePrice: Double?
    public let pnl: Double?
    public let dayChange: Double?
    public let dayChangePercentage: Double?

    enum CodingKeys: String, CodingKey {
        case tradingsymbol, exchange, isin, product, price, quantity, discrepancy, pnl
        case instrumentToken = "instrument_token"
        case t1Quantity = "t1_quantity"
        case realisedQuantity = "realised_quantity"
        case authorisedQuantity = "authorised_quantity"
        case authorisedDate = "authorised_date"
        case openingQuantity = "opening_quantity"
        case collateralQuantity = "collateral_quantity"
        case collateralType = "collateral_type"
        case averagePrice = "average_price"
        case lastPrice = "last_price"
        case closePrice = "close_price"
        case dayChange = "day_change"
        case dayChangePercentage = "day_change_percentage"
    }
}
public struct KiteGTTResponse: Sendable, Codable {
    public let triggerID: Int
    enum CodingKeys: String, CodingKey {
        case triggerID = "trigger_id"
    }
}

public struct KiteGTTCondition: Sendable, Codable {
    public let exchange: String?
    public let tradingsymbol: String?
    public let triggerValues: [Double]?
    public let lastPrice: Double?
    public let instrumentToken: UInt32?

    enum CodingKeys: String, CodingKey {
        case exchange, tradingsymbol
        case triggerValues = "trigger_values"
        case lastPrice = "last_price"
        case instrumentToken = "instrument_token"
    }
}

public struct KiteGTTOrder: Sendable, Codable {
    public let exchange: String?
    public let tradingsymbol: String?
    public let transactionType: String?
    public let quantity: Int?
    public let orderType: String?
    public let product: String?
    public let price: Double?
    public let result: KiteGTTOrderResult?

    enum CodingKeys: String, CodingKey {
        case exchange, tradingsymbol, quantity, product, price, result
        case transactionType = "transaction_type"
        case orderType = "order_type"
    }
}

public struct KiteGTTOrderResult: Sendable, Codable {
    public let orderID: String?
    public let rejectionReason: String?
    public let orderResult: KiteOrder?

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case rejectionReason = "rejection_reason"
        case orderResult = "order_result"
    }
}

public struct KiteGTTMeta: Sendable, Codable {
    public let rejectionReason: String?
    enum CodingKeys: String, CodingKey {
        case rejectionReason = "rejection_reason"
    }
}

public struct KiteGTTTrigger: Sendable, Codable {
    public let id: Int
    public let userID: String?
    public let parentTrigger: Int?
    public let type: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let expiresAt: String?
    public let status: String?
    public let condition: KiteGTTCondition?
    public let orders: [KiteGTTOrder]?
    public let meta: KiteGTTMeta?

    enum CodingKeys: String, CodingKey {
        case id, type, status, condition, orders, meta
        case userID = "user_id"
        case parentTrigger = "parent_trigger"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
    }
}

public struct KiteCandle: Sendable, Codable {
    public let timestamp: String
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Int
    public let oi: Int?
}

public struct PlaceOrderRequest: Sendable {
    public let variety, exchange, tradingsymbol, transactionType, product, orderType: String
    public let quantity: Int
    public let price, triggerPrice: Double?
    public let validity, tag: String?
    public let disclosedQuantity: Int?
    public let validityTTL: Int?
    public let marketProtection: Int?
    public let icebergLegs: Int?
    public let icebergQuantity: Int?
    public let auctionNumber: Int?
    public let autoslice: Bool?

    public init(variety: String = "regular", exchange: String, tradingsymbol: String, transactionType: String, quantity: Int, product: String, orderType: String, price: Double? = nil, triggerPrice: Double? = nil, validity: String? = nil, validityTTL: Int? = nil, tag: String? = nil, disclosedQuantity: Int? = nil, marketProtection: Int? = nil, icebergLegs: Int? = nil, icebergQuantity: Int? = nil, auctionNumber: Int? = nil, autoslice: Bool? = nil) {
        self.variety = variety; self.exchange = exchange; self.tradingsymbol = tradingsymbol; self.transactionType = transactionType
        self.quantity = quantity; self.product = product; self.orderType = orderType; self.price = price; self.triggerPrice = triggerPrice
        self.validity = validity; self.validityTTL = validityTTL; self.tag = tag; self.disclosedQuantity = disclosedQuantity
        self.marketProtection = marketProtection; self.icebergLegs = icebergLegs; self.icebergQuantity = icebergQuantity
        self.auctionNumber = auctionNumber; self.autoslice = autoslice
    }
}

public struct ModifyOrderRequest: Sendable {
    public let variety, orderID: String
    public let orderType: String?
    public let quantity: Int?
    public let price: Double?
    public let triggerPrice: Double?
    public let validity: String?
    public let disclosedQuantity: Int?
    public let parentOrderID: String?

    public init(variety: String = "regular", orderID: String, orderType: String? = nil, quantity: Int? = nil, price: Double? = nil, triggerPrice: Double? = nil, validity: String? = nil, disclosedQuantity: Int? = nil, parentOrderID: String? = nil) {
        self.variety = variety; self.orderID = orderID; self.orderType = orderType; self.quantity = quantity; self.price = price
        self.triggerPrice = triggerPrice; self.validity = validity; self.disclosedQuantity = disclosedQuantity
        self.parentOrderID = parentOrderID
    }
}
