//
//  File.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import RxCocoa

enum CommentPostFilter: Int, CaseIterable {
    case popular = 0
    case friend = 1
    case newest = 2
    
    fileprivate var param: ([String], Bool) {
        switch self {
        case .popular: return (["reactCount,DESC"], false)
        case .friend: return ([], true)
        case .newest: return (["lastUpdate,DESC"], false)
        }
    }
    
    var title: String {
        switch self {
        case .popular: return "FILTER_POST_POPULAR".localized()
        case .friend: return "FILTER_POST_FRIEND".localized()
        case .newest: return "FILTER_POST_NEWEST".localized()
        }
    }
}

enum PostDetailItem: Int {
    case detail = 0
    case comment = 1
}

struct PostTagItem {
    var id: Int
    var title: String
    var image: UIImage?
    var backgroundColor: UIColor {
        if self.image == nil { return #colorLiteral(red: 0.9450980392, green: 0.9607843137, blue: 0.968627451, alpha: 1) } else { return #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1) }
    }
    
    var attributesText: NSAttributedString {
        if self.image == nil {
            return NSAttributedString(string: self.title, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)])
        } else {
            return NSAttributedString(string: self.title, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)])
        }
    }
}

struct WrappedCommentPostAttributes {
    var comment: CommentPost
    var contentAttributes: NSAttributedString?
    var replies: [WrappedCommentPostAttributes]
    init(comment: CommentPost, contentAttributes: NSAttributedString?) {
        self.comment = comment
        self.contentAttributes = contentAttributes
        self.replies = comment.replies.map { WrappedCommentPostAttributes(comment: $0, contentAttributes: $0.attributed) }
    }
}

extension CommentPost {
    fileprivate var attributed: NSAttributedString? {
        let data = Data(self.content.utf8)
        guard let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else { return nil }

        let atrs = NSMutableAttributedString(string: attributedString.string, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: UIColor.navy])
        var context: [String: Any] = [:]
        let web: String = AppConfig.sharedConfig.get("web_url")
        self.usersTags.forEach { (profile) in
            context["id"] = profile.id
            context["prefix"] = CommentPost.USER_TAG_PREFIX
            context["url"] = URL(string: web + "users/\(profile.id)")
            #if DEBUG
            let range = (attributedString.string as NSString).range(of: profile.name.replacingOccurrences(of: "_test", with: ""))
            #else
            let range = (attributedString.string as NSString).range(of: profile.name)
            #endif
            atrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue, .autocompleted: true, .autocompletedContext: context], range: range)
        }

        self.editionTags.forEach { (book) in
            context["id"] = book.editionId
            context["prefix"] = CommentPost.BOOK_TAG_PREFIX
            context["url"] = URL(string: web + "books/\(book.editionId)")
            let range = (attributedString.string as NSString).range(of: book.title)
            atrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue, .autocompleted: true, .autocompletedContext: context], range: range)
        }
        return atrs
    }
}

struct ReplyCommentParam: ParamRequest, Hashable {
    var commentId: Int
    var lastReplyId: Int?
    var pageNum: Int
    var pageSize: Int = 10
}

fileprivate struct CommentParam: ParamRequest, Hashable {
    
    var filter: CommentPostFilter = .popular
    
    var pageNum: Int
    
    var pageSize: Int = 10
    
}

protocol PostDetailPresenter {
    
    var post: Observable<Post> { get }
    
    var items: Observable<[SectionModel<PostDetailItem, Any>]> { get }
        
    func item(indexPath: IndexPath) -> Any
    
    func section(indexPath: IndexPath) -> SectionModel<PostDetailItem, Any>
    
    func backScreen()
    
    func downloadImage(url: URL) -> Observable<UIImage>
    
    func listReply(comment: CommentPost)
    
    func nextReplies(comment: CommentPost)
    
    func nextComment()
    
    func openSortComment(sortSelection: @escaping (CommentPostFilter) -> Void)
    
    func startComment()
    
    func reply(comment: CommentPost)
    
    func edit(comment: CommentPost)
    
    func commentTags(user: Profile)
    
    func removeTags(userId: Int)
    
    func commentTags(book: BookInfo)
    
    func removeTags(editionId: Int)
    
    func sendComment(content: String)
    
    func resetComment()
    
    func remove(comment: CommentPost)
    
    func updateReactionPostWhenInteracting(reaction: UserReaction)
    
    func reactionPost(id: Post.Reaction, count: Int) -> Observable<()>
    
    func reactionComment(comment: CommentPost, reaction: Post.Reaction, count: Int)
    
    func bookmark(value: Bool)
    
    func follow(creator: PostCreator)
    
    func open(profile: Profile)
    
    func openBookDetail(book: BookInfo)
    
    func open(hashtag: Hashtag)
    
    func open(category: PostCategory)
    
    func openListReactionPost()
    
    func openListReaction(comment: CommentPost)
}

struct SimplePostDetailPresenter: PostDetailPresenter {
    var items: Observable<[SectionModel<PostDetailItem, Any>]> { self.postDetailItems.asObservable().observeOn(MainScheduler.instance).subscribeOn(MainScheduler.asyncInstance) }
    
    var post: Observable<Post> { self.article.asObservable() }
            
    fileprivate let router: PostDetailRouter
    fileprivate let imageUsecase: ImageUsecase
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let paramComment: BehaviorRelay<CommentParam>
    fileprivate let paramReply: BehaviorRelay<Set<ReplyCommentParam>>
    fileprivate let article: BehaviorRelay<Post>
    fileprivate let comments: BehaviorRelay<[WrappedCommentPostAttributes]>
    fileprivate let postDetailItems: BehaviorRelay<[SectionModel<PostDetailItem, Any>]>
    fileprivate let commentSession: BehaviorRelay<CommentPost?>
    
    init(post: Post, imageUsecase: ImageUsecase, router: PostDetailRouter) {
        self.comments = .init(value: [])
        self.commentSession = .init(value: nil)
        self.article = .init(value: post)
        self.paramComment = .init(value: .init(pageNum: 1))
        self.paramReply = .init(value: [])
        self.router = router
        self.imageUsecase = imageUsecase
        self.postDetailItems = .init(value: [])
        self.getPost()
        self.processPost()
        self.getComment()
        self.processComment()
        self.checkFollowing()
    }
    
    func item(indexPath: IndexPath) -> Any {
        self.postDetailItems.value[indexPath.section].items[indexPath.row]
    }
    
    func section(indexPath: IndexPath) -> SectionModel<PostDetailItem, Any>  {
        self.postDetailItems.value[indexPath.section]
    }
    
    func backScreen() {
        self.router.backScreen()
    }
    
    func downloadImage(url: URL) -> Observable<UIImage> {
        guard let lastComponent = url.path.split(separator: "/").last else { return .empty() }
        let domain = url.host
        let flag = domain != "fordev.gatbook.org" || domain != "production.gatbook.org"
        let size = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.last?.value ?? "o"
        let imageId = String(lastComponent)
        return !flag ? self.imageUsecase.download(imageId: imageId, size: SizeImage(rawValue: size) ?? .o)
            .compactMap { UIImage(data: $0) } : self.imageUsecase.downloadImage(url: url).compactMap { UIImage(data: $0) }
    }
    
    func listReply(comment: CommentPost) {
        var set = self.paramReply.value
        let param = ReplyCommentParam(commentId: comment.id, lastReplyId: comment.replies.first?.id, pageNum: 1, pageSize: 3)
        set.insert(param)
        self.paramReply.accept(set)
        self.getReplies(param: param)
    }

    func nextReplies(comment: CommentPost) {
        var set = self.paramReply.value
        
        guard var param = set.first(where: { $0.commentId == comment.id }) else {
            self.listReply(comment: comment)
            return
        }
        param.lastReplyId = comment.replies.first?.id
        param.pageNum += 1
        set.insert(param)
        self.paramReply.accept(set)
        self.getReplies(param: param)
    }
    
    func nextComment() {
        var param = self.paramComment.value
        param.pageNum += 1
        self.paramComment.accept(param)
    }
    
    func openSortComment(sortSelection: @escaping (CommentPostFilter) -> Void) {
        self.router.openCommentSort { (sort) in
            sortSelection(sort)
            self.paramReply.accept(.init())
            self.paramComment.accept(.init(filter: sort, pageNum: 1, pageSize: self.paramComment.value.pageSize))
        }
    }
    
    func startComment() {
        guard let user = Session.shared.user?.profile else { return }
        self.commentSession.accept(.init(id: 0, post: self.article.value, editionTags: [], usersTags: [], content: "", user: user, lastUpdate: .init(), summary: .init(reactCount: 0, replyCount: 0), replies: []))
    }
    
    func reply(comment: CommentPost) {
        guard let user = Session.shared.user?.profile else { return }
        var comment = comment
        var usersTags = comment.usersTags
        if usersTags.first?.id == user.id {
            usersTags = []
        }
        comment.replies = [.init(id: 0, post: self.article.value, editionTags: [], usersTags: usersTags, content: "", user: user, lastUpdate: .init(), summary: .init(reactCount: 0, replyCount: 0))]
        self.commentSession.accept(comment)
    }
    
    func edit(comment: CommentPost) {
        self.commentSession.accept(comment)
    }
    
    func commentTags(user: Profile) {
        guard var comment = self.commentSession.value else { return }
        if var replyComment = comment.replies.last {
            replyComment.usersTags.append(user)
            comment.replies = [replyComment]
        } else {
            comment.usersTags.append(user)
        }
        self.commentSession.accept(comment)
    }
    
    func removeTags(userId: Int) {
        guard var comment = self.commentSession.value else { return }
        if var replyComment = comment.replies.last {
            replyComment.usersTags.removeAll(where: { $0.id == userId })
            comment.replies = [replyComment]
        } else {
            comment.usersTags.removeAll(where: { $0.id == userId })
        }
        self.commentSession.accept(comment)
    }
    
    func commentTags(book: BookInfo) {
        guard var comment = self.commentSession.value else { return }
        if var replyComment = comment.replies.last {
            replyComment.editionTags.append(book)
            comment.replies = [replyComment]
        } else {
            comment.editionTags.append(book)
        }
        self.commentSession.accept(comment)
    }
    
    func removeTags(editionId: Int) {
        guard var comment = self.commentSession.value else { return }
        if var replyComment = comment.replies.last {
            replyComment.editionTags.removeAll(where: { $0.editionId == editionId })
            comment.replies = [replyComment]
        } else {
            comment.editionTags.removeAll(where: { $0.editionId == editionId })
        }
        self.commentSession.accept(comment)
    }
    
    func sendComment(content: String) {
        guard var comment = self.commentSession.value, !content.isEmpty else { return }
        
        if var replyComment = comment.replies.last, replyComment.id == .zero {
            replyComment.content = content
            self.reply(commentId: comment.id, comment: replyComment)
        } else {
            comment.content = content
            self.send(comment: comment)
        }
    }
    
    func resetComment() {
        self.commentSession.accept(nil)
    }
    
    func remove(comment: CommentPost) {
        self.router.showAlertDeleteComment {
            self.handlerRemove(comment: comment)
        }
    }
    
    func updateReactionPostWhenInteracting(reaction: UserReaction) {
        var post = self.article.value
        post.userReaction.reactionId = reaction.reactionId
        post.userReaction.reactCount += reaction.reactCount
        post.summary.reactCount += reaction.reactCount
        self.article.accept(post)
    }
    
    func reactionPost(id: Post.Reaction, count: Int) -> Observable<()>  {
        return PostService.shared.reaction(postId: self.article.value.id, reactionId: id.rawValue, reactionCount: count)
            .do (onNext: { (_) in
            }, onError: { (error) in
                var post = self.article.value
                post.userReaction.reactCount -= count
                if post.userReaction.reactCount == 0 {
                    post.userReaction.reactionId = 0
                }
                post.summary.reactCount -= count
                self.article.accept(post)
                self.router.showAlert(error: error)
            })
    }
    
    func reactionComment(comment: CommentPost, reaction: Post.Reaction, count: Int) {
        CommentPostService.shared.reaction(commentId: comment.id, reactionId: reaction.rawValue, reactionCount: count)
            .catchError({ (error) -> Observable<()> in
                HandleError.default.showAlert(with: error)
                self.comments.accept(self.comments.value)
                return .empty()
            })
            .subscribe { (_) in
                var c = comment
                c.summary.reactCount += count
                c.userReaction.reactionId = reaction.rawValue
                c.userReaction.reactCount += count 
                var comments = self.comments.value
                if let parentId = comment.parentCommentId {
                    if let parentIndex = comments.firstIndex(where: { $0.comment.id == parentId }) {
                        var parent = comments[parentIndex]
                        if let childIndex = parent.comment.replies.firstIndex(where: { $0.id == comment.id }) {
                            parent.comment.replies[childIndex] = c
                            if let index = parent.replies.firstIndex(where: { $0.comment.id == comment.id }) {
                                parent.replies[index] = .init(comment: c, contentAttributes: c.attributed)
                            }
                        }
                        comments[parentIndex] = parent
                    }
                } else {
                    if let index = comments.firstIndex(where: { $0.comment.id == comment.id }) {
                        comments[index] = .init(comment: c, contentAttributes: c.attributed)
                    }
                }
                self.comments.accept(comments)
            }
            .disposed(by: self.disposeBag)

    }
    
    func bookmark(value: Bool) {
        PostService.shared.saving(id: self.article.value.id, saving: value)
            .catchError { (error) -> Observable<()> in
                self.router.showAlert(error: error)
                self.article.accept(self.article.value)
                return .empty()
            }
            .withLatestFrom(self.post)
            .map { (post) -> Post in
                var p = post
                p.saving = value
                return p
            }
            .bind(onNext: self.article.accept)
            .disposed(by: self.disposeBag)
    }
    
    func follow(creator: PostCreator) {
        guard creator.profile.id != Session.shared.user?.id else { return }
        let observable: Observable<()>
        if creator.isFollowing {
            observable = UserFollowService.shared.follow(userId: creator.profile.id)
        } else {
            observable = UserFollowService.shared.unfollow(userId: creator.profile.id)
        }
        observable.catchError { (error) -> Observable<()> in
            self.router.showAlert(error: error)
            let items = self.postDetailItems.value
            self.postDetailItems.accept(items)
            return .empty()
        }
        .withLatestFrom(self.post)
        .map { (post) -> Post in
            var p = post
            p.creator.isFollowing = creator.isFollowing
            return p
        }
        .bind(onNext: self.article.accept)
        .disposed(by: self.disposeBag)
    }
    
    func open(profile: Profile) {
        self.router.open(profile: profile)
    }
    
    func openBookDetail(book: BookInfo) {
        self.router.openBookDetail(book: book)
    }
    
    func open(hashtag: Hashtag) {
        self.router.openDetailCollectionArticle(type: .Hashtag, hashtag: hashtag)
    }
    
    func open(category: PostCategory) {
        self.router.openDetailCollectionArticle(type: .Catergory, category: category)
    }
    
    func openListReactionPost() {
        self.router.openListUserReaction(kind: .post(self.article.value.id), totalReaction: self.article.value.summary.reactCount)
    }
    
    func openListReaction(comment: CommentPost) {
        self.router.openListUserReaction(kind: .comment(comment.id), totalReaction: comment.summary.reactCount)
        
    }
}

extension SimplePostDetailPresenter {
    fileprivate func getPost() {
        NotificationCenter.default.rx.notification(CompletePublishPostViewController.updatePost)
            .compactMap { $0.object as? Post }
            .subscribe(onNext: self.article.accept)
            .disposed(by: self.disposeBag)
        PostService.shared.post(id: self.article.value.id)
            .catchError { (error) -> Observable<Post> in
                self.router.showAlert(error: error)
                return .empty()
            }
        .subscribe(onNext: self.article.accept)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func checkFollowing() {
        self.article
            .filter { $0.creator.profile.id != 0 }
            .filter { Session.shared.isAuthenticated && $0.creator.profile.id != Session.shared.user?.id }
            .elementAt(0)
            .flatMap { UserFollowService.shared.isFollow(userId: $0.creator.profile.id) }
            .withLatestFrom(self.post) { (value, post) -> Post in
                var p = post
                p.creator.isFollowing = value
                return p
            }
            .bind(onNext: self.article.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func processPost() {
        self.article.withLatestFrom(self.postDetailItems, resultSelector: { (post, items) -> [SectionModel<PostDetailItem, Any>] in
            var items = items
            var array: [Any] = []
            if !post.title.isEmpty {
                array.append(post)
            }
            if !post.body.isEmpty {
                array.append(post.body)
            }
            if !post.editionTags.isEmpty {
                array.append(post.editionTags)
            }
            var tags: [PostTagItem] = []
            if let category = post.categories.first {
                tags = [.init(id: category.categoryId, title: category.title, image: #imageLiteral(resourceName: "combinedShapeCopy"))]
            }
            tags.append(contentsOf: post.hashtags.map { PostTagItem(id: $0.id, title: "#\($0.name)", image: nil) })
            if !tags.isEmpty {
                array.append(tags)
            }
            if !post.creator.profile.name.isEmpty {
                array.append(post.creator)
            }
            if !post.title.isEmpty {
                array.append(post.summary)
            }
            
            if let index = items.firstIndex(where: { $0.identity == .detail }) {
                items[index] = .init(model: .detail, items: array)
            } else {
                items.append(.init(model: .detail, items: array))
            }
            items.sort(by: { $0.model.rawValue < $1.model.rawValue })
            return items
        })
        .subscribe(onNext: self.postDetailItems.accept)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func processComment() {
        self.comments.withLatestFrom(self.postDetailItems.asObservable()) { (comments, items) -> [SectionModel<PostDetailItem, Any>] in
            var items = items
            if let index = items.firstIndex(where: { $0.model == .comment }) {
                items[index] = .init(model: .comment, items: comments)
            } else {
                items.append(.init(model: .comment, items: comments))
            }
            items.sort(by: { $0.model.rawValue < $1.model.rawValue })
            return items
        }
        .bind(onNext: self.postDetailItems.accept)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func getComment() {
        let id = self.article.value.id
        self.paramComment.flatMap { (param) -> Observable<[CommentPost]> in
            return CommentPostService.shared.comments(postId: id, sorts: param.filter.param.0, isFriend: param.filter.param.1, pageNum: param.pageNum, pageSize: param.pageSize)
            .catchErrorJustReturn([])
        }
        .withLatestFrom(self.post, resultSelector: { (comments, post) -> [CommentPost] in
            return comments.map { (comment) -> CommentPost in
                var c = comment
                c.post = post
                return c
            }
        })
        .filter { !$0.isEmpty }
        .bind { results in
            var comments = self.comments.value
            let list = results.map { WrappedCommentPostAttributes(comment: $0, contentAttributes: $0.attributed) }
            if self.paramComment.value.pageNum == 1 {
                comments = list
            } else {
                comments.append(contentsOf: list)
            }
            self.comments.accept(comments)
        }
        .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func getReplies(param: ReplyCommentParam) {
        CommentPostService.shared
            .replies(commentId: param.commentId, lastReplyId: param.lastReplyId, pageNum: param.pageNum, pageSize: param.pageSize)
            .do(onError: { (error) in
                self.router.showAlert(error: error)
            })
            .withLatestFrom(self.post, resultSelector: { (comments, post) -> [CommentPost] in
                return comments.map { (comment) -> CommentPost in
                    var c = comment
                    c.post = post
                    return c
                }
            })
            .catchErrorJustReturn([])
            .withLatestFrom(self.comments.asObservable()) { (replies, comments) -> [WrappedCommentPostAttributes] in
                var comments = comments
                if let index = comments.firstIndex(where: { $0.comment.id == param.commentId }) {
                    var comment = comments[index]
                    if param.pageNum == 1 {
                        if comment.comment.replies.isEmpty {
                            comment.comment.replies = replies
                            comment.replies = replies.map { WrappedCommentPostAttributes.init(comment: $0, contentAttributes: $0.attributed) }
                        } else {
                            comment.comment.replies.insert(contentsOf: replies, at: 0)
                            comment.replies.insert(contentsOf: replies.map { WrappedCommentPostAttributes(comment: $0, contentAttributes: $0.attributed) }, at: 0)
                        }
                        
                    } else {
                        comment.comment.replies.insert(contentsOf: replies, at: 0)
                        comment.replies.insert(contentsOf: replies.map { WrappedCommentPostAttributes(comment: $0, contentAttributes: $0.attributed) }, at: 0)
                    }
                    comments[index] = comment
                }
                return comments
            }
            .bind(onNext: self.comments.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func send(comment: CommentPost) {
        CommentPostService.shared.send(comment: comment)
            .catchError({ (error) -> Observable<CommentPost> in
                self.router.showAlert(error: error)
                return .empty()
            })
            .do(onNext: { (_) in
                self.resetComment()
            })
            .withLatestFrom(self.post, resultSelector: { (comment, post) -> CommentPost in
                guard let user = Session.shared.user?.profile else { return comment }
                var comment = comment
                comment.user = user
                comment.post = post
                return comment
            })
            .bind { result in
                var result = result
                if comment.id != .zero {
                    result = comment
                }
                var comments = self.comments.value
                var post = self.article.value
                if let parentId = result.parentCommentId {
                    if let parentIndex = comments.firstIndex(where: { $0.comment.id == parentId }) {
                        var parentComment = comments[parentIndex]
                        if let childIndex = parentComment.comment.replies.firstIndex(where: { $0.id == result.id }) {
                            parentComment.comment.replies[childIndex] = result
                            if let idx = parentComment.replies.firstIndex(where: { $0.comment.id == result.id}) {
                                parentComment.replies[idx] = .init(comment: result, contentAttributes: result.attributed)
                            }
                            
                            comments[parentIndex] = parentComment
                        }
                    }
                } else {
                    if let index = comments.firstIndex(where: { $0.comment.id == result.id}) {
                        comments[index] = .init(comment: result, contentAttributes: result.attributed)
                    } else {
                        comments.insert(.init(comment: result, contentAttributes: result.attributed), at: 0)
                        post.summary.commentCount += 1
                        self.article.accept(post)
                    }
                }
                self.comments.accept(comments)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func reply(commentId: Int, comment: CommentPost) {
        CommentPostService.shared.reply(commentId: commentId, comment: comment)
            .catchError { (error) -> Observable<CommentPost> in
                self.router.showAlert(error: error)
                return .empty()
        }
        .do(onNext: { (_) in
            self.resetComment()
        })
            .withLatestFrom(self.post, resultSelector: { (comment, post) -> CommentPost in
                guard let user = Session.shared.user?.profile else { return comment }
                var comment = comment
                comment.user = user
                comment.post = post
                comment.parentCommentId = commentId
                return comment
            })
            .withLatestFrom(self.comments) { (commentReply, comments) -> [WrappedCommentPostAttributes] in
                var comments = comments
                if let index = comments.firstIndex(where: { $0.comment.id == commentId }) {
                    var comment = comments[index]
                    comment.comment.replies.append(commentReply)
                    comment.replies.append(.init(comment: commentReply, contentAttributes: commentReply.attributed))
                    comment.comment.summary.replyCount += 1
                    comments[index] = comment
                }
                return comments
            }
            .bind(onNext: self.comments.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func handlerRemove(comment: CommentPost) {
        CommentPostService.shared.delete(commentId: comment.id)
            .catchError { (error) -> Observable<()> in
                self.router.showAlert(error: error)
                return .empty()
            }
        .do(onNext: { (_) in
            if let id = comment.parentCommentId {
                var set = self.paramReply.value
                if let param = set.first(where: { $0.commentId == id }) {
                    set.remove(param)
                }
                self.paramReply.accept(set)
            }
        })
            .subscribe(onNext: { (_) in
                var comments = self.comments.value
                if let id = comment.parentCommentId {
                    if let parentIndex = comments.firstIndex(where: { $0.comment.id == id }) {
                        var parentComment = comments[parentIndex]
                        parentComment.comment.replies.removeAll(where: { $0.id == comment.id })
                        parentComment.comment.summary.replyCount -= 1
                        parentComment.replies.removeAll(where: { $0.comment.id == comment.id })
                        comments[parentIndex] = parentComment
                    }
                } else {
                    comments.removeAll(where: { $0.comment.id == comment.id })
                }
                self.comments.accept(comments)
            })
            .disposed(by: self.disposeBag)
    }
    
}
