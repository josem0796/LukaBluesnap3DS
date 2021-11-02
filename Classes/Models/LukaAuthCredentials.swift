//
//  LukaAuthCredentials.swift
//  LukaiOSSDK
//
//  Created by José Daniel Gómez on 15/9/21.
//

import Foundation

public class LukaAuthCredentials: Codable {
    
    var userName: String
    var password: String
    
    public init() {
        self.userName = ""
        self.password = ""
    }
 
    public init(userName: String, password: String) {
        self.userName = userName
        self.password = password
    }
    
    enum CondingKeys: String, CodingKey {
        case userName = "Username"
        case password = "Password"
    }
    
    func basic() -> String {
        let joined = "\(userName):\(password)"
        let data = Data(joined.utf8)
        return "Basic \(data.base64EncodedString())"
    }
    
}
