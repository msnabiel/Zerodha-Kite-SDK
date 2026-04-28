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
    public let accessToken: String
    public let publicToken: String?
    public let refreshToken: String?
    public let loginTime: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id", userName = "user_name", userShortname = "user_shortname", email
        case userType = "user_type", broker, exchanges, products
        case orderTypes = "order_types", avatarURL = "avatar_url"
        case accessToken = "access_token", publicToken = "public_token", refreshToken = "refresh_token", loginTime = "login_time"
    }
}

public struct KiteOrder: Sendable, Codable {
    public let orderID: String
    public let status: String?
    public let exchange: String?
    public let tradingsymbol: String?
    public let transactionType: String?
    public let orderType: String?
    public let product: String?
    public let quantity: Int?
    public let disclosedQuantity: Int?
    public let price: Double?
    public let triggerPrice: Double?
    enum CodingKeys: String, CodingKey {
        case orderID = "order_id", status, exchange, tradingsymbol, product, quantity, price
        case transactionType = "transaction_type", orderType = "order_type"
        case disclosedQuantity = "disclosed_quantity", triggerPrice = "trigger_price"
    }
}

public struct KiteTrade: Sendable, Codable {
    public let tradeID: String?
    public let orderID: String?
    public let tradingsymbol: String?
    public let quantity: Int?
    public let price: Double?
    enum CodingKeys: String, CodingKey { case tradeID = "trade_id", orderID = "order_id", tradingsymbol, quantity, price }
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
    public let lastPrice: Double?
    public let lastQuantity: Int?
    public let averagePrice: Double?
    public let volume: Int?
    public let buyQuantity: Int?
    public let sellQuantity: Int?
    public let ohlc: KiteOHLCData?
    public let depth: KiteDepth?
    enum CodingKeys: String, CodingKey {
        case instrumentToken = "instrument_token", lastPrice = "last_price", lastQuantity = "last_quantity", averagePrice = "average_price"
        case volume, ohlc, depth, buyQuantity = "buy_quantity", sellQuantity = "sell_quantity"
    }
}

public struct KitePosition: Sendable, Codable { public let tradingsymbol: String? }
public struct KiteHolding: Sendable, Codable { public let tradingsymbol: String? }
public struct KiteGTTResponse: Sendable, Codable { public let triggerID: Int; enum CodingKeys: String, CodingKey { case triggerID = "trigger_id" } }
public struct KiteGTTTrigger: Sendable, Codable { public let id: Int; public let type: String?; public let status: String?; public let condition: [String: AnyCodable]?; public let orders: [[String: AnyCodable]]? }

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
    public let marketProtection: Int?
    public let autoslice: Bool?
    public init(variety: String = "regular", exchange: String, tradingsymbol: String, transactionType: String, quantity: Int, product: String, orderType: String, price: Double? = nil, triggerPrice: Double? = nil, validity: String? = nil, tag: String? = nil, disclosedQuantity: Int? = nil, marketProtection: Int? = nil, autoslice: Bool? = nil) {
        self.variety = variety; self.exchange = exchange; self.tradingsymbol = tradingsymbol; self.transactionType = transactionType
        self.quantity = quantity; self.product = product; self.orderType = orderType; self.price = price; self.triggerPrice = triggerPrice
        self.validity = validity; self.tag = tag; self.disclosedQuantity = disclosedQuantity; self.marketProtection = marketProtection; self.autoslice = autoslice
    }
}

public struct ModifyOrderRequest: Sendable {
    public let variety, orderID: String
    public let quantity: Int?
    public let price: Double?
    public let triggerPrice: Double?
    public let validity: String?
    public let disclosedQuantity: Int?
    public init(variety: String = "regular", orderID: String, quantity: Int? = nil, price: Double? = nil, triggerPrice: Double? = nil, validity: String? = nil, disclosedQuantity: Int? = nil) {
        self.variety = variety; self.orderID = orderID; self.quantity = quantity; self.price = price
        self.triggerPrice = triggerPrice; self.validity = validity; self.disclosedQuantity = disclosedQuantity
    }
}
