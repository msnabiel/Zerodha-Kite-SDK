import Foundation

public struct KiteMFOrder: Sendable, Codable {
    public let orderID: String?
    public let tradingsymbol: String?
    public let status: String?
    public let averagePrice: Double?
    public let quantity: Double?
    enum CodingKeys: String, CodingKey {
        case orderID = "order_id", tradingsymbol, status
        case averagePrice = "average_price"
        case quantity
    }
}

public struct KiteMFSIP: Sendable, Codable {
    public let sipID: String?
    public let tradingsymbol: String?
    public let status: String?
    enum CodingKeys: String, CodingKey { case sipID = "sip_id", tradingsymbol, status }
}

public struct KiteMFHolding: Sendable, Codable {
    public let tradingsymbol: String?
    public let quantity: Double?
    public let averagePrice: Double?
    enum CodingKeys: String, CodingKey { case tradingsymbol, quantity, averagePrice = "average_price" }
}

