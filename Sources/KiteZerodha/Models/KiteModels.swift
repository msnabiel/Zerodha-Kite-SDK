import Foundation

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

    enum CodingKeys: String, CodingKey {
        case userID = "user_id", userName = "user_name", userShortname = "user_shortname", email
        case userType = "user_type", broker, exchanges, products
        case orderTypes = "order_types", avatarURL = "avatar_url"
        case accessToken = "access_token", publicToken = "public_token", refreshToken = "refresh_token"
    }
}

public struct KiteOrder: Sendable, Codable {
    public let orderID: String
    enum CodingKeys: String, CodingKey { case orderID = "order_id" }
}

public struct KitePosition: Sendable, Codable { public let tradingsymbol: String? }
public struct KiteHolding: Sendable, Codable { public let tradingsymbol: String? }
public struct KiteGTTResponse: Sendable, Codable {
    public let triggerID: Int
    enum CodingKeys: String, CodingKey { case triggerID = "trigger_id" }
}
public struct KiteGTTTrigger: Sendable, Codable {
    public let id: Int
    public let type: String?
    public let status: String?
}

public struct PlaceOrderRequest: Sendable {
    public let variety, exchange, tradingsymbol, transactionType, product, orderType: String
    public let quantity: Int
    public let price: Double?
    public let triggerPrice: Double?
    public let validity: String?
    public let tag: String?
    public init(variety: String = "regular", exchange: String, tradingsymbol: String, transactionType: String, quantity: Int, product: String, orderType: String, price: Double? = nil, triggerPrice: Double? = nil, validity: String? = nil, tag: String? = nil) {
        self.variety = variety; self.exchange = exchange; self.tradingsymbol = tradingsymbol
        self.transactionType = transactionType; self.quantity = quantity; self.product = product; self.orderType = orderType; self.price = price
        self.triggerPrice = triggerPrice; self.validity = validity; self.tag = tag
    }
}

public struct ModifyOrderRequest: Sendable {
    public let variety, orderID: String
    public let quantity: Int?
    public let price: Double?
    public let triggerPrice: Double?
    public let validity: String?
    public init(variety: String = "regular", orderID: String, quantity: Int? = nil, price: Double? = nil, triggerPrice: Double? = nil, validity: String? = nil) {
        self.variety = variety; self.orderID = orderID; self.quantity = quantity; self.price = price
        self.triggerPrice = triggerPrice; self.validity = validity
    }
}
