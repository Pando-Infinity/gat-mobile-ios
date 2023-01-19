import Foundation
import RxSwift

class UserFollowService: NetworkService {
    
    static let shared = UserFollowService()
    
    var dispatcher: Dispatcher
    
    fileprivate init () {
        self.dispatcher = APIDispatcher()
    }
    
    func followers(of userId: Int? = nil, page: Int, per_page: Int = 10) -> Observable<[UserPublic]> {
        if let id = userId {
            return self.dispatcher.fetch(request: UserFollowerRequest(userId: id, page: page, per_page: per_page), handler: UserFollowersResponse())
        } else {
            return self.dispatcher.fetch(request: UserSelfFollowerRequest(page: page, per_page: per_page), handler: UserFollowersResponse())
        }
    }
    
    func totalFollowers(of userId: Int? = nil) -> Observable<Int> {
        if let id = userId {
            return self.dispatcher.fetch(request: UserFollowerTotalRequest(userId: id, page: 1, per_page: 10), handler: TotalResponse())
        } else {
            return self.dispatcher.fetch(request: UserSelfFollowerTotalRequest(), handler: TotalResponse())
        }
    }
    
    func follows(of userId: Int? = nil, page: Int, per_page: Int = 10) -> Observable<[UserPublic]> {
        if let id = userId {
            return self.dispatcher.fetch(request: UserFollowRequest(userId: id, page: page, per_page: per_page), handler: UserFollowersResponse())
        } else {
            return self.dispatcher.fetch(request: UserSelfFollowRequest(page: page, per_page: per_page), handler: UserFollowersResponse())
        }
    }
    
    func totalFollows(of userId: Int? =  nil) -> Observable<Int> {
        if let id = userId {
            return self.dispatcher.fetch(request: UserFollowTotalRequest(userId: id, page: 1, per_page: 10), handler: TotalResponse())
        } else {
            return self.dispatcher.fetch(request: UserSelfFollowTotalRequest(), handler: TotalResponse())
        }
    }
    
    func follow(userId: Int) -> Observable<()> {
        return self.dispatcher.fetch(request: FollowUserRequest(userId: userId), handler: IgnoreResponse())
    }
    
    func unfollow(userId: Int) -> Observable<()> {
        return self.dispatcher.fetch(request: UnFollowUserRequest(userId: userId), handler: IgnoreResponse())
    }
    
    func isFollow(userId: Int) -> Observable<Bool> {
        return self.dispatcher.fetch(request: CheckFollowUserRequest(userId: userId), handler: CheckFollowUserResponse())
    }
}
