//
//  TokenPersistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

let kOTPService = "me.mattrubin.onetimepassword.token"

public class Keychain {
    public static let sharedInstance = Keychain()
}

private extension PersistentToken {
    private init?(keychainDictionary: NSDictionary) {
        guard let urlData = keychainDictionary[kSecAttrGeneric as String] as? NSData,
            let string = NSString(data: urlData, encoding:NSUTF8StringEncoding),
            let secret = keychainDictionary[kSecValueData as String] as? NSData,
            let keychainItemRef = keychainDictionary[kSecValuePersistentRef as String] as? NSData,
            let url = NSURL(string: string as String),
            let token = Token.URLSerializer.deserialize(url, secret: secret) else {
                return nil
        }
        self.init(token: token, persistentRef: keychainItemRef)
    }
}

public extension Keychain {
    public func tokenItemForPersistentRef(persistentRef: NSData) -> PersistentToken? {
        guard let result = keychainItemForPersistentRef(persistentRef) else {
            return nil
        }
        return PersistentToken(keychainDictionary: result)
    }

    public func allTokenItems() -> [PersistentToken] {
        guard let keychainItems = allKeychainItems() else {
            return []
        }
        var items: [PersistentToken] = []
        for item: AnyObject in keychainItems {
            if let keychainDict = item as? NSDictionary,
                let tokenItem = PersistentToken(keychainDictionary: keychainDict) {
                    items.append(tokenItem)
            }
        }
        return items
    }

    public func addToken(token: Token) -> PersistentToken? {
        guard let url = Token.URLSerializer.serialize(token),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }

        let attributes = [
            kSecAttrGeneric as String:  data,
            kSecValueData as String:    token.generator.secret,
            kSecAttrService as String:  kOTPService,
        ]

        guard let persistentRef = addKeychainItemWithAttributes(attributes) else {
            return nil
        }
        return PersistentToken(token: token, persistentRef: persistentRef)
    }

    public func updateTokenItem(tokenItem: PersistentToken, withToken token: Token) -> PersistentToken? {
        guard let url = Token.URLSerializer.serialize(token),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }

        let attributes = [
            kSecAttrGeneric as String:  data
        ]

        let success = updateKeychainItemForPersistentRef(tokenItem.persistentRef,
            withAttributes: attributes)
        guard success else {
            return nil
        }
        return PersistentToken(token: token, persistentRef: tokenItem.persistentRef)
    }

    // After calling deleteTokenItem(_:), the PersistentToken's persistentRef is no longer valid, and the token item should be discarded
    public func deleteTokenItem(tokenItem: PersistentToken) -> Bool {
        return deleteKeychainItemForPersistentRef(tokenItem.persistentRef)
    }
}
