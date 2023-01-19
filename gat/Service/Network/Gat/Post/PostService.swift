//
//  PostService.swift
//  gat
//
//  Created by jujien on 9/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

struct PostService {
    
    static let shared = PostService()
    
    fileprivate let dispatcher: Dispatcher = SearchDispatcher()
    
    fileprivate init() { }
    
    func categories(title: String, pageNum: Int, pageSize: Int = 10) -> Observable<[PostCategory]> {
        self.dispatcher.fetch(request: PostCategoryRequest(title: title, pageNum: pageNum, pageSize: pageSize), handler: PostCategoryResponse())
    }
    
    func update(post: Post) -> Observable<Post> {
        self.dispatcher.fetch(request: PostUpdateRequest(post: post), handler: PostUpdateResponse())
            .map { (post) -> Post in
                var post = post
                if let profile = Session.shared.user?.profile {
                    post.creator.profile = profile
                }
                return post
            }
    }
    
    func delete(postId: Int) -> Observable<()> {
        self.dispatcher.fetch(request: DeletePostRequest(id: postId), handler: DeletePostResponse())
    }
    
    func post(id: Int) -> Observable<Post> {
        self.dispatcher.fetch(request: GetPostRequest(id: id), handler: GetPostResponse())
            .map { (post) -> Post in
                var post = post
                if post.creator.profile.id == Session.shared.user?.id {
                    post.creator.profile = Session.shared.user!.profile!
                }
                return post
        }
    }
    
    func reaction(postId: Int, reactionId: Int, reactionCount: Int) -> Observable<()> {
        self.dispatcher.fetch(request: ReactionPostRequest(postId: postId, reactCount: reactionCount, reactionId: reactionId), handler: ReactionPostResponse())
    }
    
    func getListPostChallenge(challenge:Challenge, pageNum: Int = 1, pageSize: Int = 10) -> Observable<([Post])> {
        self.dispatcher.fetch(request: GetListPostChallengeRequest(challenge: challenge, pageNum: pageNum, pageSize: pageSize), handler: GetListPostChallengeResponse())
    }
    
    func saving(id: Int, saving: Bool) -> Observable<()> {
        self.dispatcher.fetch(request: PostSavingRequest(id: id, saving: saving), handler: PostSavingResponse())
    }
    
    func getListPost(categoryIds: [Int], creatorId: Int?, editionIds: [Int], hashtagIds: [Int], states: [Post.State], title: String, pageNum: Int, pageSize: Int) -> Observable<[Post]> {
        self.dispatcher.fetch(request: GetListPostRequest(categoryIds: categoryIds, creatorId: creatorId, editionIds: editionIds, hashtagIds: hashtagIds, states: states, title: title, pageNum: pageNum, pageSize: pageSize), handler: GetListPostResponse())
    }
    
    func getMyReview(editionId: Int) -> Observable<Post> {
        self.dispatcher.fetch(request: GetPostForEditionRequest(categoryIds: [PostCategory.REVIEW_CATEGORY_ID], creatorId: nil, editionIds: [editionId], hashtagIds: [], states: [], title: "", pageNum: 1, pageSize: 10), handler: GetListPostResponse()).compactMap { $0.first }
    }
    
    func getTotalMyReview(editionId: Int) -> Observable<Int> {
        self.dispatcher.fetch(request: GetPostForEditionRequest(categoryIds: [PostCategory.REVIEW_CATEGORY_ID], creatorId: nil, editionIds: [editionId], hashtagIds: [], states: [], title: "", pageNum: 1, pageSize: 10), handler: TotalResponse())
    }
    
    func getReview(editionId: Int, pageNum: Int, pageSize: Int) -> Observable<[Post]> {
        self.getListPost(categoryIds: [PostCategory.REVIEW_CATEGORY_ID], creatorId: nil, editionIds: [editionId], hashtagIds: [], states: [], title: "", pageNum: pageNum, pageSize: pageSize)
    }
    
    func getHotWriter() -> Observable<[HotWriter]>{
        self.dispatcher.fetch(request: HotWriterRequest(), handler: HotWriterResponse())
    }
    
    func getAllPost(pageNum:Int,pageSize:Int = 10) -> Observable<[Post]>{
        self.dispatcher.fetch(request: ListAllArticleResquest(pageNum: pageNum, pageSize: pageSize), handler: GetListPostChallengeResponse())
    }
    
    func getAllNewReviewPost(pageNum:Int,pageSize:Int = 10) -> Observable<[Post]>{
        self.dispatcher.fetch(request: ListNewPostReviewRequest(pageNum: pageNum, pageSize: pageSize), handler: GetListPostChallengeResponse())
    }
    
    func getCatergory(pageNum:Int,pageSize:Int = 10,arrCatergory:[Int])-> Observable<[Post]> {
        self.dispatcher.fetch(request: ListCatergoryArticleResquest(pageNum: pageNum, pageSize: pageSize, catergory: arrCatergory), handler: GetListPostChallengeResponse())
    }
    
    func getHashtag(pageNum:Int,pageSize:Int = 10,arrHashtag:[Int])-> Observable<[Post]> {
        self.dispatcher.fetch(request: ListHashtagArticleResquest(pageNum: pageNum, pageSize: pageSize, hashtag: arrHashtag), handler: GetListPostChallengeResponse())
    }
    
    func getSavedPost(pageNum:Int,pageSize:Int = 10) -> Observable<[Post]> {
        self.dispatcher.fetch(request: ListSavedArticleResquest(pageNum: pageNum, pageSize: pageSize), handler: GetListPostChallengeResponse())
    }
    
    func totalSavedPost()->Observable<Int>{
        self.dispatcher.fetch(request: ListSavedArticleResquest(pageNum: 1, pageSize: 10), handler: TotalSavedPostResponse())
    }
    
    func getDraftPost(pageNum:Int,pageSize:Int = 10) -> Observable<[Post]> {
        self.dispatcher.fetch(request: ListDraftArticleResquest(pageNum: pageNum, pageSize: pageSize), handler: GetListPostChallengeResponse())
    }
    
    func getUserPost(userId:Int,pageNum:Int,pageSize:Int = 10,title:String) -> Observable<[Post]>{
        self.dispatcher.fetch(request: ListArticleUserRequest(pageNum: pageNum, pageSize: pageSize, userId: userId, title: title), handler: GetListPostChallengeResponse())
    }
    
    func getTotalUserPost(userId:Int,pageNum:Int,pageSize:Int = 10) -> Observable<Int>{
        self.dispatcher.fetch(request: ListArticleUserRequest(pageNum: pageNum, pageSize: pageSize, userId: userId), handler: TotalSavedPostResponse())
    }
    
    func getTotalSelfPost(pageNum:Int,pageSize:Int = 10) -> Observable<Int>{
        self.dispatcher.fetch(request: ListSelfArticleResquest(pageNum: pageNum, pageSize: pageSize), handler: TotalSavedPostResponse())
    }
    
    func getTrending(pageNum:Int,pageSize:Int = 10) -> Observable<[Post]>{
        self.dispatcher.fetch(request: TrendingPostRequest(pageNum: pageNum, pageSize: pageSize), handler: GetListPostChallengeResponse())
    }
    
    func getBookStopMemberPost(pageNum:Int,pageSize:Int = 10,bookstopId:Int) -> Observable<[Post]>{
        self.dispatcher.fetch(request: BookStopMemberPostRequest(pageNum: pageNum, pageSize: pageSize, bookstopId: bookstopId), handler: GetListPostChallengeResponse())
    }
    
    func getPopularBookStopPost(pageNum:Int,pageSize:Int = 10,bookstopId:Int) -> Observable<[Post]> {
        self.dispatcher.fetch(request: BookStopPopularPostRequest(pageNum: pageNum, pageSize: pageSize, bookstopId: bookstopId), handler: GetListPostChallengeResponse())
    }
    
    func getListUserReaction(postId: Int, pageNum: Int, pageSize: Int) -> Observable<([UserReactionInfo], Int)> {
        self.dispatcher.fetch(request: ListReactionPostRequest(postId: postId, pageNum: pageNum, pageSize: pageSize), handler: ListReactionPostResponse())
    }
    
}
