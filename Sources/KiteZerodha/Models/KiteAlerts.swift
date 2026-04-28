import Foundation

public struct KiteAlert: Sendable, Codable {
    public let type: String?
    public let userID: String?
    public let uuid: String
    public let name: String?
    public let status: String?
    public let disabledReason: String?
    public let lhsAttribute: String?
    public let lhsExchange: String?
    public let lhsTradingsymbol: String?
    public let `operator`: String?
    public let rhsType: String?
    public let rhsConstant: Double?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case type
        case userID = "user_id"
        case uuid
        case name
        case status
        case disabledReason = "disabled_reason"
        case lhsAttribute = "lhs_attribute"
        case lhsExchange = "lhs_exchange"
        case lhsTradingsymbol = "lhs_tradingsymbol"
        case `operator`
        case rhsType = "rhs_type"
        case rhsConstant = "rhs_constant"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct KiteAlertCreateRequest: Sendable {
    public let fields: [String: String]
    public init(fields: [String: String]) { self.fields = fields }
}

public struct KiteAlertModifyRequest: Sendable {
    public let fields: [String: String]
    public init(fields: [String: String]) { self.fields = fields }
}

public struct KiteAlertHistoryEvent: Sendable, Codable {
    public let uuid: String?
    public let createdAt: String?
    public let message: String?
    enum CodingKeys: String, CodingKey { case uuid, message, createdAt = "created_at" }
}

