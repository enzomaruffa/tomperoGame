//
//  StringExtensions.swift
//  Tompero
//

import Foundation
import CryptoKit

extension String {
    /// Hex-encoded MD5 of the UTF-8 bytes. Kept on MD5 (via CryptoKit's
    /// `Insecure.MD5`) to preserve compatibility with existing match-hash
    /// values stored in CloudKit — not used in a security context.
    var md5Value: String {
        guard let data = data(using: .utf8) else { return "" }
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
