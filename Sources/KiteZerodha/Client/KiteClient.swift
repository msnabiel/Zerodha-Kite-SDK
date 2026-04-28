import Foundation
import CryptoKit

public enum KiteError: Error { case missingAccessToken, invalidURL, apiError(String), decodingError }
private struct KiteEnvelope<T: Decodable>: Decodable { let status: String; let data: T?; let message: String? }

public final class KiteClient: @unchecked Sendable {
    public let apiKey: String
    public private(set) var accessToken: String?
    private let session: URLSession
    private let apiRoot = KiteZerodha.apiRoot
    private let loginRoot = KiteZerodha.loginRoot

    public init(apiKey: String, accessToken: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey; self.accessToken = accessToken; self.session = session
    }

    public func loginURL(redirectParams: String? = nil) -> URL {
        var c = URLComponents(url: loginRoot, resolvingAgainstBaseURL: false)!
        c.queryItems = [.init(name: "v", value: KiteZerodha.apiVersion), .init(name: "api_key", value: apiKey), .init(name: "redirect_params", value: redirectParams)]
        return c.url!
    }

    public func setAccessToken(_ token: String) { accessToken = token }

    public func generateSession(requestToken: String, apiSecret: String) async throws -> KiteSession {
        let checksum = Self.sha256Hex(apiKey + requestToken + apiSecret)
        let s: KiteSession = try await request(path: "/session/token", method: "POST", form: ["api_key": apiKey, "request_token": requestToken, "checksum": checksum], requiresAuth: false)
        accessToken = s.accessToken
        return s
    }

    public func orders() async throws -> [KiteOrder] { try await request(path: "/orders", method: "GET") }
    public func positions() async throws -> [String: [KitePosition]] { try await request(path: "/portfolio/positions", method: "GET") }
    public func holdings() async throws -> [KiteHolding] { try await request(path: "/portfolio/holdings", method: "GET") }

    public func placeOrder(_ req: PlaceOrderRequest) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(req.variety)", method: "POST", form: [
            "exchange": req.exchange,
            "tradingsymbol": req.tradingsymbol,
            "transaction_type": req.transactionType,
            "quantity": String(req.quantity),
            "product": req.product,
            "order_type": req.orderType,
            "price": req.price.map { String($0) } ?? "",
            "trigger_price": req.triggerPrice.map { String($0) } ?? "",
            "validity": req.validity ?? "",
            "tag": req.tag ?? "",
        ].filter { !$0.value.isEmpty })
        return data.orderID
    }

    public func modifyOrder(_ req: ModifyOrderRequest) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(req.variety)/\(req.orderID)", method: "PUT", form: [
            "quantity": req.quantity.map { String($0) } ?? "",
            "price": req.price.map { String($0) } ?? "",
            "trigger_price": req.triggerPrice.map { String($0) } ?? "",
            "validity": req.validity ?? "",
        ].filter { !$0.value.isEmpty })
        return data.orderID
    }

    public func cancelOrder(variety: String = "regular", orderID: String) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(variety)/\(orderID)", method: "DELETE")
        return data.orderID
    }

    public func placeGTT(type: String, conditionJSON: String, ordersJSON: String) async throws -> KiteGTTResponse {
        try await request(path: "/gtt/triggers", method: "POST", form: ["type": type, "condition": conditionJSON, "orders": ordersJSON])
    }

    private func request<T: Decodable>(path: String, method: String, form: [String: String]? = nil, requiresAuth: Bool = true) async throws -> T {
        var req = URLRequest(url: apiRoot.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue(KiteZerodha.apiVersion, forHTTPHeaderField: "X-Kite-Version")
        if requiresAuth {
            guard let token = accessToken else { throw KiteError.missingAccessToken }
            req.setValue("token \(apiKey):\(token)", forHTTPHeaderField: "Authorization")
        }
        if let form {
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = form.map { "\($0.key.urlQueryEscaped)=\($0.value.urlQueryEscaped)" }.joined(separator: "&").data(using: .utf8)
        }
        let (d, _) = try await session.data(for: req)
        let env = try JSONDecoder().decode(KiteEnvelope<T>.self, from: d)
        guard env.status == "success", let data = env.data else { throw KiteError.apiError(env.message ?? "unknown") }
        return data
    }

    public static func sha256Hex(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
