//
//  Post.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

struct Post {
    var id: Int
    var title: String
    var intro: String
    var body: String
    var creator: PostCreator
    var categories: [PostCategory]
    var postImage: PostImage
    var editionTags: [BookInfo]
    var userTags: [Profile]
    var hashtags: [Hashtag]
    var state: State
    var date: PostDate
    var summary: PostSummary
    var userReaction: UserReaction
    var rating: Double
    var saving: Bool
    
    var reviewCategory: PostCategory? { self.categories.first(where: { $0.categoryId == PostCategory.REVIEW_CATEGORY_ID }) }
    
    var isReview: Bool { self.reviewCategory != nil }
    
    var isInteracted: Bool { self.userReaction.reactionId != .zero }
    
    init(id: Int = 0, title: String, intro: String, body: String, creator: PostCreator, categories: [PostCategory] = [], postImage: PostImage = .init(), editionTags: [BookInfo] = [], userTags: [Profile] = [], hashtags: [Hashtag] = [], state: State = .draft, date: PostDate = .init(),userReaction: UserReaction = .init(), summary: PostSummary = .init(), rating: Double = 0.0, saving: Bool = false) {
        self.id = id
        self.title = title
        self.body = body
        self.intro = intro
        self.creator = creator
        self.categories = categories
        self.postImage = postImage
        self.editionTags = editionTags
        self.userTags = userTags
        self.hashtags = hashtags
        self.state = state
        self.date = date
        self.userReaction = userReaction
        self.summary = summary
        self.rating = rating
        self.saving = saving
    }
}

extension Post {
    enum State: Int {
        case draft = 0
        case notPublished = 1
        case published = 2
    }
}

struct PostImage {
    var thumbnailId: String
    var coverImage: String
    var bodyImages: [String]
    
    init(thumbnailId: String = "", coverImage: String = "", bodyImages: [String] = []) {
        self.thumbnailId = thumbnailId
        self.coverImage = coverImage
        self.bodyImages = bodyImages
    }
    
    mutating func add(imageId: String) {
        if self.bodyImages.isEmpty {
            self.coverImage = imageId
            self.thumbnailId = imageId
            
        }
        self.bodyImages.append(imageId)
    }
    
    mutating func remove(imageId: String) {
        self.bodyImages.removeAll(where: { $0 == imageId })
        if self.bodyImages.isEmpty {
            if imageId == self.coverImage && imageId == self.thumbnailId {
                self.coverImage = ""
                self.thumbnailId = ""
            }
        } else {
            if imageId == self.coverImage && imageId == self.thumbnailId {
                self.coverImage = self.bodyImages.first!
                self.thumbnailId = self.coverImage
            }
        }
    }
}

struct PostDate {
    var scheduledPost: Date?
    var lastUpdate: Date?
    var publishedDate: Date?
    
    init(scheduledPost: Date? = nil, lastUpdate: Date? = nil, publishedDate: Date? = nil) {
        self.scheduledPost = scheduledPost
        self.lastUpdate = lastUpdate
        self.publishedDate = publishedDate
    }
}

struct UserReaction {
    
    static let MAX = 5
    
    var reactionId: Int
    var reactCount: Int
    
    init(reactionId:Int = 0,reactCount:Int = 0){
        self.reactionId = reactionId
        self.reactCount = reactCount
    }
}

struct UserReactionInfo {
    var userReaction: UserReaction
    var profile: Profile
}

struct PostSummary {
    var reactCount: Int
    var commentCount: Int
    var shareCount: Int
    
    init(reactCount: Int = 0, commentCount: Int = 0, shareCount: Int = 0) {
        self.reactCount = reactCount
        self.commentCount = commentCount
        self.shareCount = shareCount
    }
}


struct PostCreator {
    var profile: Profile
    var isFollowing: Bool
}
struct PostCategory {
    static let REVIEW_CATEGORY_ID = 0
    var categoryId: Int
    var title: String
}

extension PostCategory: ObjectConvertable {
    func asObject() -> PostCategoryObject {
        let object = PostCategoryObject()
        object.categoryId = self.categoryId
        object.title = self.title
        return object
    }
}

extension Post {
    static let example = Post(id: 84, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false))
}

extension Post {
    enum Reaction: Int {
        case like = 1
        case love = 2
        case impe = 3
    }
}

extension Post: ObjectConvertable {
    func asObject() -> PostObject {
        let object = PostObject()
        object.id = self.id
        object.title = self.title
        object.intro = self.intro
        object.body = self.body
        object.creator = self.creator.profile.asObject()
        object.categories.append(objectsIn: self.categories.map { $0.asObject() })
        object.thumbnailId = self.postImage.thumbnailId
        object.coverImage = self.postImage.coverImage
        object.bodyImages.append(objectsIn: self.postImage.bodyImages)
        object.editionTags.append(objectsIn: self.editionTags.map { $0.asObject() })
        object.userTags.append(objectsIn: self.userTags.map { $0.asObject() })
        object.hashtags.append(objectsIn: self.hashtags.map { $0.asObject() })
        object.state = self.state.rawValue
        object.scheduledPost = self.date.scheduledPost
        object.lastUpdate = self.date.lastUpdate
        object.publishedDate = self.date.publishedDate
        object.reactCount = self.summary.reactCount
        object.commentCount = self.summary.commentCount
        object.shareCount = self.summary.shareCount
        object.reactionId = self.userReaction.reactionId
        object.reactionCount = self.userReaction.reactCount
        object.rating = self.rating
        object.saving = self.saving
        return  object
    }
}

class PostObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var intro: String = ""
    @objc dynamic var body: String = ""
    @objc dynamic var creator: ProfileObject?
    var categories: List<PostCategoryObject> = .init()
    @objc dynamic var thumbnailId: String = ""
    @objc dynamic var coverImage: String = ""
    var bodyImages: List<String> = .init()
    var editionTags: List<BookInfoObject> = .init()
    var userTags: List<ProfileObject> = .init()
    var hashtags: List<HashtagObject> = .init()
    @objc dynamic var state: Int = 0
    @objc dynamic var scheduledPost: Date?
    @objc dynamic var lastUpdate: Date?
    @objc dynamic var publishedDate: Date?
    @objc dynamic var reactCount: Int = 0
    @objc dynamic var commentCount: Int = 0
    @objc dynamic var shareCount: Int = 0
    @objc dynamic var reactionId: Int = 0
    @objc dynamic var reactionCount: Int = 0
    @objc dynamic var rating: Double = 0.0
    @objc dynamic var saving: Bool = false
    
    
    override class func primaryKey() -> String? { "id" }
    
    
}

extension PostObject: DomainConvertable {
    func asDomain() -> Post {
        return .init(
            id: self.id,
            title: self.title,
            intro: self.intro,
            body: self.body,
            creator: PostCreator(profile: self.creator?.asDomain() ?? .init(), isFollowing: false),
            categories: self.categories.map { $0.asDomain() },
            postImage: PostImage(thumbnailId: self.thumbnailId, coverImage: self.coverImage, bodyImages: self.bodyImages.map { $0 }),
            editionTags: self.editionTags.map { $0.asDomain() },
            userTags: self.userTags.map { $0.asDomain() },
            hashtags: self.hashtags.map { $0.asDomain() },
            state: Post.State(rawValue: self.state) ?? .draft,
            date: PostDate(scheduledPost: self.scheduledPost, lastUpdate: self.lastUpdate, publishedDate: self.publishedDate),
            userReaction: UserReaction(reactionId: self.reactionId, reactCount: self.reactionCount),
            summary: PostSummary(reactCount: self.reactCount, commentCount: self.commentCount, shareCount: self.shareCount),
            rating: self.rating,
            saving: self.saving
        )
    }
}

extension PostObject: PrimaryValueProtocol {
    func primaryValue() -> Int {
        self.id
    }
}

class PostCategoryObject: Object {
    @objc dynamic var categoryId: Int = 0
    @objc dynamic var title: String = ""
    
    override class func primaryKey() -> String? { "categoryId" }
}

extension PostCategoryObject: DomainConvertable {
    func asDomain() -> PostCategory {
        return .init(categoryId: self.categoryId, title: self.title)
    }
}

extension PostCategoryObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        self.categoryId
    }
}

