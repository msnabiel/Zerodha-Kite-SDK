import Foundation

public enum KiteZerodha {
    public static let apiVersion = "3"
    public static let apiRoot = URL(string: "https://api.kite.trade")!
    public static let loginRoot = URL(string: "https://kite.zerodha.com/connect/login")!
    public static let websocketRoot = URL(string: "wss://ws.kite.trade")!
}
