import Foundation

extension Data {
    func readUInt16BE(at o: Int) -> UInt16 { (UInt16(self[o]) << 8) | UInt16(self[o + 1]) }
    func readInt32BE(at o: Int) -> Int32 {
        Int32(bitPattern: (UInt32(self[o]) << 24) | (UInt32(self[o + 1]) << 16) | (UInt32(self[o + 2]) << 8) | UInt32(self[o + 3]))
    }
}

extension String {
    var urlQueryEscaped: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&="))) ?? self
    }
}
