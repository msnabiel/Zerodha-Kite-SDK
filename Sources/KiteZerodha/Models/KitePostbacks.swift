import Foundation
import CryptoKit

public enum KitePostback {
    public static func checksum(orderID: String, orderTimestamp: String, apiSecret: String) -> String {
        KiteClient.sha256Hex(orderID + orderTimestamp + apiSecret)
    }

    public static func validateChecksum(orderID: String, orderTimestamp: String, apiSecret: String, checksum: String) -> Bool {
        self.checksum(orderID: orderID, orderTimestamp: orderTimestamp, apiSecret: apiSecret) == checksum.lowercased()
    }
}

