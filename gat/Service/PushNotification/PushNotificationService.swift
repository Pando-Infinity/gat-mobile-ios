//
//  PushNotificationService.swift
//  gat
//
//  Created by Vũ Kiên on 15/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import UserNotifications
import Firebase

class PushNotificationService: NSObject {
    
    static let shared = PushNotificationService()
    
    fileprivate var application: UIApplication
    fileprivate var appDelegate: AppDelegate
    fileprivate var disposeBag = DisposeBag()
    
    fileprivate override init() {
        self.application = UIApplication.shared
        self.appDelegate = self.application.delegate as! AppDelegate
        super.init()
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        Messaging.messaging().token { result, error in
            print("FCM registion token:\(result)")
        }
    }
    
    func connectToFcm() {
       
    }
    
    //MARK: - Handle Receive Notification
    fileprivate func navigatorController(pushType: Int, userInfo: [String: Any]) {
        switch pushType {
        case 1, 4, 122, 123:
            var senderId: Int?
            if let senderIDString = userInfo["senderId"] as? String, let id = Int(senderIDString) {
                senderId = id
            } else if let requestIDString = userInfo["requestId"] as? String, let requestID = Int(requestIDString) {
                senderId = requestID
            }
            guard let senderID = senderId else { break }
            guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get() else { break }
            let messageStoryboard = UIStoryboard(name: Gat.Storyboard.MESSAGE, bundle: nil)
            let messageVC = messageStoryboard.instantiateViewController(withIdentifier: Gat.View.MessageViewController) as! MessageViewController
            var group = GroupMessage()
            group.groupId = user.id < senderID ? "\(user.id):\(senderID)" : "\(senderID):\(user.id)"
            if let result = Repository<GroupMessage, GroupMessageObject>.shared.get(predicateFormat: "groupId = %@", args: [group.groupId]) {
                group = result
            } else {
                if let friend = Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [senderID]) {
                    group.users.append(friend)
                } else {
                    let profile = Profile()
                    profile.id = senderID
                    group.users.append(profile)
                }
            }
            messageVC.lastUpdated.accept(Date())
            messageVC.group.onNext(group)
            UIApplication.topViewController()?.navigationController?.pushViewController(messageVC, animated: true)
            break
        case 2, 3, 5...8, 11, 121:
            guard let requestIDString = userInfo["requestId"] as? String, let requestID = Int(requestIDString) else {
                break
            }
            if pushType == 2 {
                let storyboard = UIStoryboard(name: Gat.Storyboard.REQUEST_DETAIL_O, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "RequestOwnerViewController") as! RequestOwnerViewController
                Repository<BookRequest, BookRequestObject>
                    .shared
                    .getAll(predicateFormat: "recordId = %@", args: [requestID])
                    .map { (results) -> BookRequest in
                        if results.first != nil {
                            return results.first!
                        } else {
                            let bookRequest = BookRequest()
                            bookRequest.recordId = requestID
                            return bookRequest
                        }
                    }
                    .subscribe(onNext: vc.bookRequest.onNext)
                    .disposed(by: self.disposeBag)
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            } else {
                //borrower
                let storyboard = UIStoryboard(name: Gat.Storyboard.REQUEST_DETAIL_S, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "RequestBorrowerViewController") as! RequestBorrowerViewController
                Repository<BookRequest, BookRequestObject>
                    .shared
                    .getAll(predicateFormat: "recordId = %@", args: [requestID])
                    .map { (results) -> BookRequest in
                        if results.first != nil {
                            return results.first!
                        } else {
                            let bookRequest = BookRequest()
                            bookRequest.recordId = requestID
                            return bookRequest
                        }
                    }
                    .subscribe(onNext: vc.bookRequest.onNext)
                    .disposed(by: self.disposeBag)
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            }
            break
        case 9, 10, 120:
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            vc.isShowButton.onNext(true)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break
        case 20, 21:
            guard let bookIdString = userInfo["bookId"] as? String, let bookId = Int(bookIdString) else {
                break
            }
            let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ListBorrowViewController.className) as! ListBorrowViewController
            let bookInfo = BookInfo()
            bookInfo.editionId = bookId
            vc.bookInfo.onNext(bookInfo)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break 
        case 200, 203:
            let storyboard = UIStoryboard(name: Gat.Storyboard.BARCODE, bundle: nil)
            let barcodeVC = storyboard.instantiateViewController(withIdentifier: Gat.View.BARCODE_CONTROLLER) as! BarcodeScannerController
            UIApplication.topViewController()?.navigationController?.pushViewController(barcodeVC, animated: true)
            break
        case 201:
            let storyboard = UIStoryboard(name: Gat.Storyboard.CURRENT_MAP, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.REGISTER_SELECT_LOCATION_CONTROLLER) as! MapViewController
            vc.isUpdating.onNext(true)
            vc.isEditMap.onNext(true)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break
        case 202:
            let storyboard = UIStoryboard(name: Gat.Storyboard.USER_FAVOURITE_CATEGORY, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.FAVOURITE_CATEGORY_CONTROLLER) as! FavoriteCategoryViewController
            vc.isEditingFavourite.onNext(false)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break
        case 301:
            let storyboard = UIStoryboard(name: Gat.Storyboard.NEARBY_USER, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.NEARBY_USER_CONTROLLER)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break
        case 401:
            guard let bookIdString = userInfo["bookId"] as? String, let bookId = Int(bookIdString) else {
                break
            }
            let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.BOOKDETAIL_CONTROLLER) as! BookDetailViewController
            let book = BookInfo()
            book.editionId = bookId
            vc.bookInfo.onNext(book)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break
        case 402:
            guard let bookIds = userInfo["bookIds"] as? String else { return }
            let storyboard = UIStoryboard.init(name: Gat.Storyboard.Main, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ExploreBookViewController.className) as! ExploreBookViewController
            vc.editionIds.onNext(bookIds.split(separator: ",").map { "\($0.replacingOccurrences(of: " ", with: ""))" }.filter { $0.isNumber }.map { Int($0) }.filter { $0 != nil }.map { $0!} )
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            break
        case 403:
            guard let fblink = userInfo["fbLink"] as? String, let url = URL(string: fblink) else { break }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { (status) in
                }
            } else {
                UIApplication.shared.openURL(url)
            }
            break
        //gioi thieu user
        case 404:
            guard let userIdString = userInfo["userId"] as? String , let userId = Int(userIdString) else {return}
            if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userId {
                let user = UserPrivate()
                user.profile!.id = userId
                let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                vc.isShowButton.onNext(true)
                vc.userPrivate.onNext(user)
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            } else {
                let user = UserPublic()
                user.profile = Profile()
                user.profile.id = userId
                let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
                vc.userPublic.onNext(user)
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            }
        //man review
        case 405:
            guard let reviewIdString = userInfo["reviewId"] as? String , let reviewId = Int(reviewIdString) else {return}
            let review = Review()
            review.reviewId = reviewId
            let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ReviewViewController.className) as! ReviewViewController
            vc.review.onNext(review)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        case 406:
            guard let challengeIdString = userInfo["requestId"] as? String , let challengeId = Int(challengeIdString) else {return}
            let storyboard = UIStoryboard(name: "ChallengeDetailView", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ChallengeDetailVC.className) as! ChallengeDetailVC
            vc.idChallenge = challengeId
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        case 500:
            guard let followerIdString = userInfo["senderId"] as? String, let followerId = Int(followerIdString) else { return }
            let user = UserPublic()
            user.profile = Profile()
            user.profile.id = followerId
            let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
            vc.userPublic.onNext(user)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        case 502:
            let storyboard = UIStoryboard(name: "Follow", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: FollowViewController.className) as! FollowViewController
            vc.type.onNext(.follower)
            vc.user.onNext(Repository<UserPrivate, UserPrivateObject>.shared.get()?.profile ?? Profile())
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        case 600:
            guard let editionIdString = userInfo["editionId"] as? String, let editionId = Int(editionIdString) else { return }
            let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
            let book = BookInfo()
            book.editionId = editionId
            vc.bookInfo.onNext(book)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        case 800, 801, 802, 803:
            guard let challengeIdString = userInfo["requestId"] as? String, let challengeId = Int(challengeIdString) else {return}
            let storyboard = UIStoryboard(name: ChallengeDetailVC.storyboardName, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ChallengeDetailVC.className) as! ChallengeDetailVC
            vc.idChallenge = challengeId
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        case 900,901,904,905,908,910:
            guard let articleIdString = userInfo["requestId"] as? String, let articleId = Int(articleIdString) else {return}
            let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
            let postDetail = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
            let post = Post.init(id: articleId, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false), categories: .init(), postImage: .init(), editionTags: [], userTags: [], hashtags: [], state: .published, date: .init(), userReaction: .init(), summary: .init(), rating: 0.0, saving: false)
            postDetail.presenter = SimplePostDetailPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: postDetail))
            UIApplication.topViewController()?.navigationController?.pushViewController(postDetail, animated: true)
        case 902,903,906,907,909:
            guard let articleIdString = userInfo["requestId"] as? String, let articleId = Int(articleIdString) else {return}
            let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
            let postDetail = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
            let post = Post.init(id: articleId, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false), categories: .init(), postImage: .init(), editionTags: [], userTags: [], hashtags: [], state: .published, date: .init(), userReaction: .init(), summary: .init(), rating: 0.0, saving: false)
            postDetail.presenter = SimplePostDetailPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: postDetail))
            UIApplication.topViewController()?.navigationController?.pushViewController(postDetail, animated: true)
        default:
            break
        }
    }

}

extension PushNotificationService {
    func register() {
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            guard !UIApplication.shared.isRegisteredForRemoteNotifications else { return }
            center.requestAuthorization(options: [.badge, .sound, .alert]) { [unowned self] (grant, error) in
                if let error = error {
                    print("error: " + error.localizedDescription)
                }
//                if grant {
//                    DispatchQueue.main.async { [unowned self] in
//                        self.application.registerForRemoteNotifications()
//                    }
//                    //self.connectToFcm()
//                } else {
//                    print("User didn't grant permission")
//                }
            }
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            // Fallback on earlier versions
            guard !UIApplication.shared.isRegisteredForRemoteNotifications else { return }
            let notificationSetting = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            self.application.registerUserNotificationSettings(notificationSetting)
            self.application.registerForRemoteNotifications()
//            self.connectToFcm()
        }
    }
    
    func handle(userInfo: [String: Any]) {
        guard let pushTypeString = userInfo["pushType"] as? String, let pushType = Int(pushTypeString) else {
            return
        }
        self.navigatorController(pushType: pushType, userInfo: userInfo)
    }
    
    func error(_ error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
}

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
         print("Firebase registration token: \(fcmToken)")
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(notification.request.content.userInfo)
        NotificationNetworkService
            .shared
            .notifyTotal()
            .catchErrorJustReturn(0)
            .subscribe(onNext: { [weak self] (total) in
                if let vc = self?.appDelegate.window?.rootViewController as? TabBarController {
                    vc.tabBar.items?[3].badgeValue = total > 0 ? "\(total)" : nil
                }
            })
            .disposed(by: self.disposeBag)
        completionHandler([.badge, .alert, .sound])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String: Any] {
            self.handle(userInfo: userInfo)
        }
        completionHandler()
    }
}

