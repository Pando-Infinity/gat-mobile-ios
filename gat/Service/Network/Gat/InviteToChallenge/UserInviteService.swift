//
//  UserInviteService.swift
//  gat
//
//  Created by macOS on 9/14/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

class UserInviteToChallenge{
    static let shared:UserInviteToChallenge = UserInviteToChallenge()
    
    var dispatcher:Dispatcher
    
    fileprivate init(){
        self.dispatcher = SearchDispatcher()
    }
    
    func inviteUserById(challenge:Challenge, userIds:[Int]) -> Observable<()>{
        return self.dispatcher.fetch(request: InviteToChallengeRequest(challenge: challenge, arrUserId: userIds), handler: InviteToChallengeResponse())
    }
    
    func listSearchInvitable(challenge: Challenge,page: Int, per_page: Int = 10,username:String) -> Observable<[UserPublic]>{
        return self.dispatcher.fetch(request: UserInviteListSearchRequest(challenge: challenge, pageNum: page, pageSize: 10, username: username), handler: UserInviteRespone())
    }
}

struct UserInviteListSearchRequest: APIRequest {
    var path: String {return "challenges/\(self.challenge.id)/invitable_users"}
    
    var method: HTTPMethod {.get}
    
    var parameters: Parameters? {
        
        if let userName = self.username {
            return ["pageNum":self.pageNum,"pageSize":self.pageSize,"username":userName,"filter":2,"sorts":"invited,ASC"]
        } else {
           return ["pageNum":self.pageNum,"pageSize":self.pageSize,"filter":2,"sorts":"invited,ASC"]
        }
    }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    var challenge:Challenge
    
    var pageNum:Int
    
    var pageSize:Int
    
    var username:String?
}

struct UserInviteRespone: APIResponse{
    func map(data: Data?, statusCode: Int) -> [UserPublic]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.compactMap({ (item) -> UserPublic? in
            let user = UserPublic()
            user.profile.id = item["userId"].intValue
            user.profile.imageId = item["imageId"].stringValue
            user.profile.username = item["username"].stringValue
            user.profile.name = item["name"].stringValue
            user.invited = item["invited"].boolValue
            return user
        })
    }
}
