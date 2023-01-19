//
//  CommentPost.swift
//  gat
//
//  Created by jujien on 9/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

struct CommentPost {
    
    static let USER_TAG_PREFIX = "@"
    static let BOOK_TAG_PREFIX = "&"
    
    var id: Int
    var post: Post
    var editionTags: [BookInfo]
    var usersTags: [Profile]
    var content: String
    var user: Profile
    var lastUpdate: Date
    var summary: CommentPostSummary
    var replies: [CommentPost]
    var parentCommentId: Int?
    var userReaction: UserReaction
    
    var isReaction: Bool { self.userReaction.reactionId != .zero }
    
    init(id: Int, post: Post, editionTags: [BookInfo], usersTags: [Profile], content: String, user: Profile, lastUpdate: Date, summary: CommentPostSummary, replies: [CommentPost] = [], userReaction: UserReaction = .init()) {
        self.id = id
        self.post = post
        self.editionTags = editionTags
        self.usersTags = usersTags
        self.content = content
        self.user = user
        self.lastUpdate = lastUpdate
        self.summary = summary
        self.replies = replies
        self.userReaction = userReaction
    }
    
    func findComment(id: Int) -> CommentPost? {
        guard id == self.id else { return self }
        return self.replies.first(where: { $0.id == id })
    }
}

struct CommentPostSummary {
    var reactCount: Int
    var replyCount: Int
}

struct TagComment {
    
    var id: Int
    var text: String
    
    init(id: Int, text: String) {
        self.id = id
        self.text = text
    }
}

extension TagComment: Hashable {
    static func == (lhs: TagComment, rhs: TagComment) -> Bool {
        return lhs.id == rhs.id && lhs.text == rhs.text
    }
}
