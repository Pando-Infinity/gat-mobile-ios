//
//  MessageService.swift
//  gat
//
//  Created by Vũ Kiên on 15/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import RealmSwift

class MessageService {
    
    static let shared = MessageService()
    
    fileprivate let db: Firestore = Firestore.firestore()
    fileprivate let disposeBag: DisposeBag
    
    fileprivate var groupsNotRead: Set<String> = .init()
    
    fileprivate init() {
        self.disposeBag = DisposeBag()
    }
    
    func configure() {
    }

    func numberMessageNotRead() -> Observable<Int> {
//        return Repository<GroupMessage, GroupMessageObject>.shared.getAll(predicateFormat: "lastMessage.isRead = %@", args: [false])
//            .map { $0.count }
        guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get() else { return Observable.empty() }
        return Repository<GroupMessage, GroupMessageObject>.shared
            .getAll(sortBy: "lastUpdated", ascending: false).map { $0.first?.lastUpdated ?? Date() }
            .flatMap { [weak self] (date) -> Observable<GroupMessage> in
                return .create { (observer) -> Disposable in
                    self?.db.collection("groups")
                    .whereField("participants", arrayContains: user.id)
                    .whereField("last_updated", isLessThanOrEqualTo: date)
                        .getDocuments(completion: { (query, error) in
                            if let query = query {
                                query.documentChanges.filter { $0.type != .modified }.compactMap { (document) -> GroupMessage? in
                                    let group = GroupMessage()
                                    group.groupId = document.document.documentID
                                    group.lastMessage = Message(dict: document.document.data()["last_message"] as! [String: Any])
                                    guard !group.lastMessage!.isRead else { return nil }
                                    group.lastUpdated = (document.document.data()["last_updated"] as! Timestamp).dateValue()
                                    let id = (document.document.data()["participants"] as! [Int]).filter { $0 != group.users.first!.id }.first!
                                    if let user = Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [id]) {
                                        group.users.append(user)
                                        group.lastMessage?.user = user
                                    } else {
                                        let user = Profile()
                                        user.id = id
                                        group.users.append(user)
                                    }
                                    group.messages.append(group.lastMessage!)
                                    return group
                                }
                                .forEach { (group) in
                                    observer.onNext(group)
                                }
                            }
                            if let error = error {
                                observer.onError(error)
                            }
                        })
                    return Disposables.create {}
                }
        }
        .flatMap { Repository<GroupMessage, GroupMessageObject>.shared.save(object: $0) }
            .flatMap { _ in Repository<GroupMessage, GroupMessageObject>.shared.getAll(predicateFormat: "lastMessage.isRead = %@", args: [false]) }
            .do(onNext: { [weak self] (groups) in
                groups.map { $0.groupId }.forEach { self?.groupsNotRead.insert($0) }
            })
            .compactMap { [weak self] _ in self?.groupsNotRead.count }
    }
    
    func listenNumberMessageNotRead() -> Observable<Int> {
        guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get() else { return Observable.empty() }
        return Repository<GroupMessage, GroupMessageObject>.shared
        .getAll(sortBy: "lastUpdated", ascending: false).map { $0.first?.lastUpdated ?? Date() }
        .flatMap { (date) -> Observable<GroupMessage> in
            return Observable<GroupMessage>.create({ [weak self] (observer) -> Disposable in
                let listener = self?.db.collection("groups")
                    .whereField("participants", arrayContains: user.id)
                    .whereField("last_updated", isGreaterThanOrEqualTo: date)
                    .addSnapshotListener { (query, error) in
                        if let query = query {
                            query.documentChanges.compactMap { (document) -> GroupMessage? in
                                guard document.type != .removed else { return nil }
                                let group = GroupMessage()
                                group.groupId = document.document.documentID
                                group.lastUpdated = (document.document.data()["last_updated"] as! Timestamp).dateValue()
                                group.lastMessage = Message(dict: document.document.data()["last_message"] as! [String: Any])
                                let user = Profile()
                                group.messages.append(group.lastMessage!)
                                user.id = (document.document.data()["participants"] as! [Int]).filter { $0 != group.users.first!.id }.first!
                                group.users.append(user)
                                return group
                                
                            }
                            .filter { $0.lastMessage?.user?.id != user.id }
                            .forEach(observer.onNext)
                        }
                        if let error = error {
                            observer.onError(error)
                        }
                }
                return Disposables.create {
                    listener?.remove()
                }
            })
        }
        .do(onNext: { [weak self] (group) in
            guard let lastMessage = group.lastMessage else { return }
            if lastMessage.isRead {
                self?.groupsNotRead.remove(group.groupId)
                self?.updateBadge()
            } else {
                self?.groupsNotRead.insert(group.groupId)
            }
        })
            .compactMap { [weak self] _ in self?.groupsNotRead.count }
    }
    
    func groupsWithLastMessage(lastUpdated: Date? = nil, perPage: Int = 12) -> Observable<[GroupMessage]> {
        guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get(), let date = lastUpdated  else { return Observable.empty() }
        return Observable<[GroupMessage]>.create { [weak self] (observer) -> Disposable in
            self?.db.collection("groups")
                .whereField("participants", arrayContains: user.id)
                .whereField("last_updated", isLessThan: date)
                .order(by: "last_updated", descending: true)
                .limit(to: perPage)
                .getDocuments(completion: { (query, error) in
                    if let query = query {
                        let results = query.documentChanges.map { (document) -> GroupMessage in
                            let group = GroupMessage()
                            group.groupId = document.document.documentID
                            group.lastMessage = Message(dict: document.document.data()["last_message"] as! [String: Any])
                            group.lastUpdated = (document.document.data()["last_updated"] as! Timestamp).dateValue()
                            let user = Profile()
                            user.id = (document.document.data()["participants"] as! [Int]).filter { $0 != group.users.first!.id }.first!
                            group.messages.append(group.lastMessage!)
                            group.users.append(user)
                            return group

                        }
                        observer.onNext(results)
                    }
                    if let error = error {
                        observer.onError(error)
                    }
                })
            return Disposables.create()
            }
        .filter { _ in Status.reachable.value }
            .flatMap({ (groups) -> Observable<[GroupMessage]> in
                var list = [GroupMessage]()
                return Observable<GroupMessage>.from(groups)
                    .flatMap({ (group) -> Observable<GroupMessage> in
                        let friendId = group.users.last!.id
                        group.users.removeLast()
                        if let user = Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [friendId]), !user.name.isEmpty {
                            group.users.append(user)
                            return Observable.just(group)
                        } else {
                            let userPublic = UserPublic()
                            userPublic.profile.id = friendId
                            return UserNetworkService.shared.publicInfo(user: userPublic.profile)
                                .catchErrorJustReturn(userPublic)
                                .map({ (user) -> Profile in
                                    group.users.append(user.profile)
                                    return user.profile
                                })
                                .flatMap { Repository<Profile, ProfileObject>.shared.save(object: $0) }
                                .map { _ in group }
                        }
                    })
                    .do(onNext: { (group) in
                        list.append(group)
                    })
                    .filter { _ in groups.count == list.count }
                    .map { _ in list }
            })
    }
    
    func listenGroupsWithLastMessage() -> Observable<GroupMessage> {
        guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get() else { return Observable.empty() }
        return Repository<GroupMessage, GroupMessageObject>.shared
            .getAll(sortBy: "lastUpdated", ascending: false).map { $0.first?.lastUpdated ?? Date() }
            .flatMap { (date) -> Observable<GroupMessage> in
                return Observable<GroupMessage>.create({ [weak self] (observer) -> Disposable in
                    let listener = self?.db.collection("groups")
                        .whereField("participants", arrayContains: user.id)
                        .whereField("last_updated", isGreaterThanOrEqualTo: date)
                        .addSnapshotListener { (query, error) in
                            if let query = query {
                                query.documentChanges.compactMap { (document) -> GroupMessage? in
                                    guard document.type != .removed else { return nil }
                                    let group = GroupMessage()
                                    group.groupId = document.document.documentID
                                    group.lastUpdated = (document.document.data()["last_updated"] as! Timestamp).dateValue()
                                    group.lastMessage = Message(dict: document.document.data()["last_message"] as! [String: Any])
                                    let user = Profile()
                                    group.messages.append(group.lastMessage!)
                                    user.id = (document.document.data()["participants"] as! [Int]).filter { $0 != group.users.first!.id }.first!
                                    group.users.append(user)
                                    return group
                                    
                                }
                                .forEach(observer.onNext)
                            }
                            if let error = error {
                                observer.onError(error)
                            }
                    }
                    return Disposables.create {
                        listener?.remove()
                    }
                })
            }
            .filter { _ in Status.reachable.value }
            .flatMap({ (group) -> Observable<GroupMessage> in
                let friendId = group.users.last!.id
                group.users.removeLast()
                let userPublic = UserPublic()
                userPublic.profile.id = friendId
                if let profile = Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [friendId]), !profile.name.isEmpty {
                    group.users.append(profile)
                    return Observable.just(group)
                } else {
                    return UserNetworkService.shared.publicInfo(user: userPublic.profile)
                        .catchErrorJustReturn(userPublic)
                        .do(onNext: { (user) in
                            group.users.append(user.profile)
                        })
                        .flatMap { Repository<Profile, ProfileObject>.shared.save(object: $0.profile) }
                        .map { _ in group }
                }
            })
            .map({ (group) -> GroupMessage in
                if group.messages.first?.user?.id != User.adminId {
                    group.messages.first?.user = group.users.first(where: {$0.id == group.messages.first!.user!.id})
                }
                return group
            })
    }
    
    func listen(in groupId: String) -> Observable<Message> {
        return Observable<Message>.create { [weak self] (observer) -> Disposable in
            let listener = self?.db.collection("messages").document("\(groupId)").collection("chats")
                .whereField("timestamp", isGreaterThan: Date())
                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
                    if let query = query {
                        query.documentChanges.compactMap({ (document) -> Message? in
                            if document.type == .added {
                                let message = Message(dict: document.document.data())
                                message.messageId = document.document.documentID
                                return message
                            } else {
                                return nil
                            }
                        }).forEach(observer.onNext)
                    }
                    if let error = error {
                        observer.onError(error)
                    }
                })
            return Disposables.create {
                listener?.remove()
            }
        }
            .filter { _ in Status.reachable.value }
            .map({ (message) -> Message in
                if let user = Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [message.user!.id]) {
                    message.user = user
                }
                return message
            })
    }
    
    func message(in group: String, lastUpdate: Date? = nil, perPage: Int = 12) -> Observable<[Message]> {
        guard let date = lastUpdate else { return .empty() }
        return Observable<[Message]>.create({ [weak self] (observer) -> Disposable in
            self?.db.collection("messages").document(group).collection("chats")
                .order(by: "timestamp", descending: true)
                .whereField("timestamp", isLessThan: date)
                .limit(to: perPage)
                .getDocuments { (query, error) in
                    if let query = query {
                        let messages = query.documentChanges.map({ (document) -> Message in
                            let message = Message(dict: document.document.data())
                            message.messageId = document.document.documentID
                            return message
                        })
                        observer.onNext(messages)
                    }
                    if let error = error {
                        observer.onError(error)
                    }
            }
            return Disposables.create()
        })
            .filter { _ in Status.reachable.value }
            .map({ (messages) -> [Message] in
                return messages.map({ (message) -> Message in
                    if let user = Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [message.user!.id]) {
                        message.user = user
                    }
                    return message
                })
            })
            .flatMap({ (messages) -> Observable<[Message]> in
                guard let user = messages.first(where: { $0.user?.name.isEmpty == true && $0.user?.id != 0 })?.user else { return Observable.just(messages) }
                let userPublic = UserPublic()
                userPublic.profile = user
                return UserNetworkService.shared.publicInfo(user: user)
                    .catchErrorJustReturn(userPublic)
                    .map { $0.profile }
                    .do(onNext: { (user) in
                        messages.filter {$0.user?.name.isEmpty == true }.forEach({ (message) in
                            message.user = user
                        })
                    })
                    .flatMap { Repository<Profile, ProfileObject>.shared.save(object: $0) }
                    .map { _ in messages }
            })
    }
    
    func send(message: Message, in group: GroupMessage) -> Observable<()> {
        let sendMessage = Observable<()>.create { [weak self] (observer) -> Disposable in
            self?.db.collection("messages")
                .document(group.groupId)
                .collection("chats").document(message.messageId)
                .setData(message.data) { (error) in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                    }
            }
            return Disposables.create()
        }
        let lastMessage = Observable<()>.create { [weak self] (observer) -> Disposable in
            self?.db.collection("groups")
                .document(group.groupId)
                .setData(["last_message": message.data, "participants": group.users.map { $0.id }, "last_updated": message.sendDate], completion: { (error) in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                    }
                })
            return Disposables.create()
        }
        return Observable.combineLatest(sendMessage, lastMessage).map { $0.0 }
    }
    
    func updateReadStatus(group: GroupMessage) -> Observable<()> {
        guard let lastMessage = group.lastMessage else { return Observable.empty() }
//        let messages = Observable<Message>.from(group.messages)
//            .flatMap { (message) -> Observable<()> in
//                Observable<()>.create { [weak self] (observer) -> Disposable in
//                    self?.db.collection("messages")
//                        .document(group.groupId)
//                        .collection("chats")
//                        .document(message.messageId)
//                        .updateData(message.data) { (error) in
//                            if let error = error {
//                                observer.onError(error)
//                            } else {
//                                observer.onNext(())
//                            }
//                    }
//                    return Disposables.create()
//                }
//        }
        
        let groups = Observable<()>.create { [weak self] (observer) -> Disposable in
            self?.db.collection("groups")
                .document(group.groupId)
                .updateData(["last_message": lastMessage.data, "participants": group.users.map { $0.id }, "last_updated": group.lastUpdated], completion: { (error) in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                    }
                })
            return Disposables.create()
        }
        return groups
//        return Observable.combineLatest(messages, groups).map { $0.0 }
    }
    
    func disconnect() {
    }
    
    fileprivate func updateBadge() {
        guard UIApplication.shared.applicationIconBadgeNumber > 0 else { return }
        UIApplication.shared.applicationIconBadgeNumber -= 1
    }
    
}
