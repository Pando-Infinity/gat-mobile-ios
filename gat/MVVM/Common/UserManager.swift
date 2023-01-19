//
//  UserManager.swift
//  gat
//
//  Created by Hung Nguyen on 1/29/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//
// Use this class to save and get data of User
import Foundation

class UserManager {
    
    static let shared = UserManager()
    
    init() {}
    
    private let USER_ID = "UserId"
    private let TOKEN = "Token"
    
    // Set User Id
    func setUserId(_ userId: Int) {
        UserDefaults.standard.set(userId, forKey: USER_ID)
    }
    
    func getUserId() -> Int {
        return UserDefaults.standard.integer(forKey: USER_ID)
    }
    
    // Set User Token
    func setToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: TOKEN)
    }
    
    func getToken() -> String {
        return UserDefaults.standard.string(forKey: TOKEN) ?? ""
    }
    
    func clear() {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
    }
}
