import Foundation
import Alamofire

class UserSelfFollowerRequest: APIRequest {
    var path: String { return "users/self/followers" }
    
    var parameters: Parameters? { return ["page": self.page, "per_page": self.per_page] }
    
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(page: Int, per_page: Int) {
        self.page = page
        self.per_page = per_page
    }
}

class UserSelfFollowerTotalRequest: APIRequest {
    var path: String { return "users/self/followers/total" }
}

class UserFollowerRequest: APIRequest {
    var path: String { return "users/\(self.userId)/followers" }
    
    var parameters: Parameters? { return ["page": self.page, "per_page": self.per_page] }
    
    fileprivate let userId: Int
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(userId: Int, page: Int, per_page: Int) {
        self.userId = userId
        self.page = page
        self.per_page = per_page
    }
}

class UserFollowerTotalRequest: UserFollowerRequest {
    override var path: String { return "users/\(self.userId)/followers/total" }
}


class CheckFollowUserRequest: APIRequest {
    var path: String { return "users/self/isFollowing/\(self.userId)" }
    
    fileprivate let userId: Int
    
    init(userId: Int) {
        self.userId = userId
    }
}

class CheckFollowUserResponse: APIResponse {
    typealias Resource = Bool
    
    func map(data: Data?, statusCode: Int) -> Bool? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        return json["data"].bool
    }
}

class UserFollowersResponse: APIResponse {
    typealias Resource = [UserPublic]
    
    func map(data: Data?, statusCode: Int) -> [UserPublic]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.compactMap({ (item) -> UserPublic? in
            guard let id = item["userId"].int else { return nil }
            let user = UserPublic()
            let profile = Profile()
            profile.id = id
            profile.about = item["about"].string ?? ""
            profile.address = item["address"].string ?? ""
            profile.imageId = item["imageId"].string ?? ""
            profile.name = item["name"].string ?? ""
            profile.userTypeFlag = UserType(rawValue: item["userTypeFlag"].int ?? 1) ?? .normal
            profile.coverImageId = item["coverImageId"].string ?? ""
            user.profile = profile
            user.followedByMe = item["followedByMe"].bool ?? false
            user.followMe = item["followMe"].bool ?? false
            user.sharingCount = item["sharingCount"].int ?? 0
            user.reviewCount = item["reviewCount"].int ?? 0
            return user
        })
    }
    
    
}
