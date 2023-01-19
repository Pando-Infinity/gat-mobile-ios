//
//  InviteChallenge.swift
//  gat
//
//  Created by macOS on 9/13/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire

struct InviteToChallengeRequest:APIRequest {
    var path: String {return "challenges/\(challenge.id)/_invite"}
    
    var method: HTTPMethod {return .post}
    
    var parameters: Parameters?
    {
        return ["userIds": self.arrUserId]
    }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    var encoding: ParameterEncoding {return JSONEncoding.default}
    let challenge: Challenge
    let arrUserId: [Int]
}

struct InviteToChallengeResponse:APIResponse {
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode)  else { return nil }
        print(json)
        return ()
    }
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
