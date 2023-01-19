//
//  SmallArticleBookstopCollectionViewCell.swift
//  gat
//
//  Created by jujien on 8/10/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Lottie

class SmallArticleBookstopCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "smallArticleBookstopCell" }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    fileprivate var contentPostView: SmallArticleView!
    
    fileprivate let disposeBag = DisposeBag()
    
    let post = BehaviorRelay<Post?>(value: nil)
    var sizeCell: CGSize = .zero
    var tapCellToOpenPostDetail:((OpenPostDetail,Bool)->Void)?
    var tapBook:((Bool)->Void)?
    var tapCatergory:((Bool)->Void)?
    var tapUser:((Bool)->Void)?
    
    var showUser: ((Profile) -> Void)? {
        didSet {
            self.contentPostView.showUser = self.showUser
        }
    }
    var showOption: ((Post,Bool) -> Void)? {
        didSet {
            self.contentPostView.showOption = self.showOption
        }
    }
    
    var reactCount:Int = 0
    var userReactCount:Int = 0
    var likeEvent: ((Post.Reaction, Int) -> Void)?
    var commentEvent: ((Post) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func showAnimation() {
        let animationView = AnimationView(name: "heart")
        animationView.backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        self.contentView.insertSubview(animationView, belowSubview: self.heartButton)
        animationView.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.heartButton.snp.leading).offset(12.0)
            maker.bottom.equalTo(self.heartButton.snp.bottom).offset(-25.0)
            maker.height.equalTo(200)
            maker.width.equalTo(45.0)
        }

        animationView.play { (status) in
            guard status else { return }
            animationView.removeFromSuperview()
        }
    }
    
    fileprivate func showReactionCount() {
        let view = UIView()
        view.backgroundColor = .grapefruit
        
        self.contentView.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.heartButton.snp.leading).offset(12.0)
            maker.width.equalTo(view.snp.height)
            maker.width.equalTo(35.0)
            maker.bottom.equalTo(self.heartButton.snp.top).offset(-8.0)
        }
        view.layer.masksToBounds = true
        view.cornerRadius(radius: 17.5)
        view.alpha = .zero

        let label = UILabel()
        if self.userReactCount > UserReaction.MAX {
            self.userReactCount = UserReaction.MAX
        }
        label.text = "+\(self.userReactCount)"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12.0, weight: .semibold)
        label.textAlignment = .center
        view.addSubview(label)
        
        label.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        UIView.animate(withDuration: 0.15, animations: {
            view.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.5, animations: {
                view.alpha = .zero
            }) { (_) in
                view.removeFromSuperview()
            }
        }
    }
    
    fileprivate func setupUI() {
        self.heartButton.setTitle("LOVE_POST_TITLE".localized(), for: .normal)
        self.commentButton.setTitle("COMMENT_POST_TITTLE".localized(), for: .normal)
        
        self.cornerRadius(radius: 10.0)
        self.contentPostView = Bundle.main.loadNibNamed(SmallArticleView.className, owner: self, options: nil)?.first as? SmallArticleView
        self.containerView.addSubview(self.contentPostView)
        self.post.compactMap { $0?.isInteracted }.map { $0 ? #imageLiteral(resourceName: "h") : #imageLiteral(resourceName: "heart") }.bind(to: self.heartButton.rx.image(for: .normal)).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.isInteracted }.subscribe(onNext: { (tap) in
            if tap == true {
                self.heartButton.setTitleColor(UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
            } else {
                self.heartButton.setTitleColor(UIColor.brownGrey, for: .normal)
            }
        }).disposed(by: self.disposeBag)
        
        self.contentPostView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.leading.equalToSuperview()
        }
        self.post.subscribe(onNext: self.contentPostView.post.accept).disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.sizeCell != .zero {
                layout.frame.size = self.sizeCell
            }
        }
        return layout
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.tapBtnLove()
        self.tapBtnComment()
        self.tapImgUser()
        self.tapPost()
        self.tapBookTitle()
    }
    
    fileprivate func tapBtnLove(){
        var timer:Timer?
        
//        Observable.combineLatest(self.heartButton.rx.controlEvent(.touchDown).asObservable(),Observable.just(self.contentPostView) , Observable.just(self))
//            .do(onNext: { (_,view,vc) in
//                guard Session.shared.isAuthenticated else {
//                    HandleError.default.loginAlert()
//                    return
//                }
//                self.heartButton.setTitleColor(UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
//                self.showAnimation()
//                self.heartButton.setImage(UIImage.init(named: "h"), for: .normal)
//                timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true, block: { (_) in
//                    self.showAnimation()
//                    if vc.reactCount < UserReaction.MAX {
//                        vc.reactCount += 1
//                        self.showReactionCount()
//                        var post = vc.post.value
//                        post?.summary.reactCount += self.reactCount
//                        view?.numberHeartLabel.text = "\(post?.summary.reactCount ?? 0)"
//                    } else {
//                        timer?.invalidate()
//                        timer = nil
//                    }
//                    self.showReactionCount()
//                })
//            }).bind { [weak self] (_) in
//                self?.likeEvent?(.love,self?.reactCount ?? 0)
//                self?.reactCount = 0
//            }
//            .disposed(by: self.disposeBag)
        
        self.post.subscribe { (post) in
            self.userReactCount = post?.userReaction.reactCount ?? 0
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.heartButton.rx.tap.asObservable(),Observable.just(self.contentPostView) , Observable.just(self))
            .do(onNext: { (_,view,vc) in
                guard Session.shared.isAuthenticated else {
                    HandleError.default.loginAlert()
                    return
                }
                self.showAnimation()
                self.heartButton.setTitleColor(UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
                self.heartButton.setImage(UIImage.init(named: "h"), for: .normal)
                if vc.userReactCount < UserReaction.MAX {
                    vc.userReactCount += 1
                    vc.reactCount += 1
                    self.showReactionCount()
                    var post = vc.post.value
                    post?.summary.reactCount += self.reactCount
                    view?.numberHeartLabel.text = "\(post?.summary.reactCount ?? 0)"
                }
                self.showReactionCount()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { (_) -> Observable<Timer> in
                timer?.invalidate()
                timer = nil
                return Observable<Timer>.create { (observer) -> Disposable in
                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
                        observer.onNext(timer)
                    })
                    return Disposables.create {
                        timer?.invalidate()
                        timer = nil
                    }
                }
            }.bind { [weak self] (_) in
                if self!.userReactCount <= UserReaction.MAX {
                    self?.likeEvent?(.love,self?.reactCount ?? 0)
                }
                self?.reactCount = 0
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tapBtnComment(){
        self.commentButton.rx.tap.withLatestFrom(self.post.asObservable()).compactMap { $0 }
        .subscribe(onNext: { [weak self] (post) in
            self?.commentEvent?(post)
        })
        .disposed(by: self.disposeBag)
        
        self.commentButton.rx.tapGesture().when(.recognized)
        .subscribe(onNext: { (_) in
            self.tapCellToOpenPostDetail?(OpenPostDetail.OpenWithComment,true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapImgUser(){
        self.contentPostView.userImageView.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            self.tapUser?(true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapBookTitle(){
        self.contentPostView.infoBookLabel.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            guard let arrCater = self.post.value?.categories else {return}
            if arrCater.contains(where: {$0.categoryId == 0}){
                self.tapBook?(true)
            } else {
                self.tapCatergory?(true)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapPost(){
        let stackView:[UIView] = [self.contentPostView.viewContent]
        for i in stackView {
            i.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { (_) in
                    self.tapCellToOpenPostDetail?(OpenPostDetail.OpenNormal,true)
                }).disposed(by: self.disposeBag)
        }
    }
}

extension SmallArticleBookstopCollectionViewCell {
    
    static let HEIGHT: CGFloat = 278.0
    
    fileprivate static let INTERACTIVE_BUTTON_HEIGHT: CGFloat = 44.0
    fileprivate static let SEPERATE_VIEW_HEIGHT: CGFloat = 1.0
    
    class func size(post: Post, in estimatedSize: CGSize) -> CGSize {
        let postSize = SmallArticleView.size(post: post, estimatedSize: estimatedSize)
        return .init(width: postSize.width, height: postSize.height + SmallArticleBookstopCollectionViewCell.INTERACTIVE_BUTTON_HEIGHT + SmallArticleBookstopCollectionViewCell.SEPERATE_VIEW_HEIGHT)
    }
}
