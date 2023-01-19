//
//  CommentPostService.swift
//  gat
//
//  Created by jujien on 9/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

struct CommentPostService {
    
    static let shared = CommentPostService()
    fileprivate let dispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = DataDispatcher(host: AppConfig.sharedConfig.config(item: "api_url_v2")!)
    }
    
    func comments(postId: Int, sorts: [String], isFriend: Bool, pageNum: Int, pageSize: Int, lastCommentId: Int? = nil) -> Observable<[CommentPost]> {
        self.dispatcher.fetch(request: ListCommentPostRequest(postId: postId, sorts: sorts, isFriend: isFriend, pageNum: pageNum, pageSize: pageSize, lastCommentId: lastCommentId), handler: ListCommentPostResponse())
    }
    
    func send(comment: CommentPost) -> Observable<CommentPost> {
        self.dispatcher.fetch(request: CreateCommentPostRequest(comment: comment), handler: CreateCommentPostResponse())
            .map { (result) -> CommentPost in
                var result = result
                result.parentCommentId = comment.parentCommentId
                return result
            }
    }
    
    func delete(commentId: Int) -> Observable<()> {
        return self.dispatcher.fetch(request: DeleteCommentPostRequest(id: commentId), handler: DeleteCommentPostResponse())
    }
    
    func replies(commentId: Int, lastReplyId: Int? = nil, pageNum: Int, pageSize: Int,isNewer: Bool? = nil) -> Observable<[CommentPost]> {
        self.dispatcher.fetch(request: ListReplyCommentPostRequest(isNewer: isNewer, commentId: commentId, lastReplyId: lastReplyId, pageNum: pageNum, pageSize: pageSize), handler: ListReplyCommentPostResponse())
            .map { (comments) -> [CommentPost] in
                return comments.map { (comment) -> CommentPost in
                    var c = comment
                    c.parentCommentId = commentId
                    return c
                }
            }
    }
    
    func totalReplies(commentId:Int,pageNum:Int = 1,pageSize:Int = 2) -> Observable<Int>{
        self.dispatcher.fetch(request: ListReplyCommentPostRequest(isNewer: nil, commentId: commentId, lastReplyId: nil, pageNum: pageNum, pageSize: pageSize), handler: TotalResponse())
    }
    
    func reply(commentId: Int, comment: CommentPost) -> Observable<CommentPost> {
        self.dispatcher.fetch(request: ReplyCommentPostRequest(replyCommentId: commentId, comment: comment), handler: ReplyCommentPostResponse())
    }
    
    func reaction(commentId: Int, reactionId: Int, reactionCount: Int) -> Observable<()> {
        self.dispatcher.fetch(request: ReactionCommentPostRequest(commentId: commentId, reactCount: reactionCount, reactionId: reactionId), handler: ReactionCommentPostResponse())
    }
    
    func listReactionComment(id: Int, pageNum: Int, pageSize: Int) -> Observable<([UserReactionInfo], Int)> {
        self.dispatcher.fetch(request: ListReactionCommentPostRequest(commentId: id, pageNum: pageNum, pageSize: pageSize), handler: ListReactionCommentPostResponse())
    }
}

