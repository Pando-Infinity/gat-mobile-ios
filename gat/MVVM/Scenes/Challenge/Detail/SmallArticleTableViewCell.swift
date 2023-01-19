//
//  SmallArticleTableViewCell.swift
//  gat
//
//  Created by macOS on 10/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Lottie

enum OpenPostDetail:Int{
    case OpenWithComment = 2
    case OpenNormal = 1
}
class SmallArticleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var btnLove:UIButton!
    @IBOutlet weak var btnComment:UIButton!
    @IBOutlet weak var containerView:UIView!
    @IBOutlet weak var viewReactAndComment:UIView!
    
    fileprivate var contentPostView: SmallArticleView!
    var tapCellToOpenPostDetail:((OpenPostDetail,Bool)->Void)?
    var tapBook:((Bool)->Void)?
    var tapCatergory:((Bool)->Void)?
    var tapUser:((Bool)->Void)?
    var giveAction: (() -> Void)?
    
    let post = BehaviorRelay<Post?>(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
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
        // Initialization code
        self.setupUI()
        self.event()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    fileprivate func setupUI() {
        LanguageHelper.changeEvent.subscribe { (_) in
            self.btnLove.setTitle("LOVE_POST_TITLE".localized(), for: .normal)
            self.btnComment.setTitle("COMMENT_POST_TITTLE".localized(), for: .normal)
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)

        self.btnLove.setTitle("LOVE_POST_TITLE".localized(), for: .normal)
        self.btnComment.setTitle("COMMENT_POST_TITTLE".localized(), for: .normal)
        self.cornerRadius(radius: 10.0)
        self.contentPostView = Bundle.main.loadNibNamed(SmallArticleView.className, owner: self, options: nil)?.first as? SmallArticleView
        self.containerView.addSubview(self.contentPostView)
        self.post.compactMap { $0?.isInteracted }.map { $0 ? #imageLiteral(resourceName: "h") : #imageLiteral(resourceName: "heart") }.bind(to: self.btnLove.rx.image(for: .normal)).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.isInteracted }.subscribe(onNext: { (tap) in
            if tap == true {
                self.btnLove.setTitleColor(UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
            } else {
                self.btnLove.setTitleColor(UIColor.brownGrey, for: .normal)
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
    
    fileprivate func event() {
        self.tapBtnLove()
        self.tapBtnComment()
        self.tapImgUser()
        self.tapPost()
        self.tapBookTitle()
    }
    
    fileprivate func showAnimation() {
        let animationView = AnimationView(name: "heart")
        animationView.animationSpeed = 0.5
        animationView.backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        self.contentView.insertSubview(animationView, belowSubview: self.btnLove)
        animationView.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.btnLove.snp.leading).offset(12.0)
            maker.bottom.equalTo(self.btnLove.snp.bottom).offset(-25.0)
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
            maker.centerX.equalTo(self.btnLove.snp.leading).offset(12.0)
            maker.width.equalTo(view.snp.height)
            maker.width.equalTo(35.0)
            maker.bottom.equalTo(self.btnLove.snp.top).offset(-8.0)
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
        UIView.animate(withDuration: 0.5, animations: {
            view.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.5, animations: {
                view.alpha = .zero
            }) { (_) in
                view.removeFromSuperview()
            }
        }
    }
    
    fileprivate func tapBtnLove(){
        var timer:Timer?
        
        self.post.subscribe { (post) in
            self.userReactCount = post?.userReaction.reactCount ?? 0
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)
        self.btnLove.rx.longPressGesture().when(.ended)
            .do(onNext: {  (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .filter { _ in timer != nil }
            .do { _ in
                timer?.invalidate()
                timer?.fire()
                timer = nil
            }
            .filter { _ in self.reactCount != 0 }
            .bind { [weak self] (_) in
                if self!.userReactCount <= UserReaction.MAX {
                    self?.likeEvent?(.love,self?.reactCount ?? 0)
                }
                self?.reactCount = 0
            }
            .disposed(by: self.disposeBag)
        
        
        self.btnLove.rx.longPressGesture()
            .when(.began, .ended)
            .do { _ in
                guard Session.shared.isAuthenticated else {
                    HandleError.default.loginAlert()
                    return
                }
                
            }
            .filter { _ in Session.shared.isAuthenticated }
            .filter { _ in self.btnLove.imageView?.image != UIImage(named: "h") }
            .flatMap({ _ in
                return Observable<Timer?>.create { (observer) -> Disposable in
                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                        observer.onNext(timer)
                    })
                    return Disposables.create {
                        timer?.invalidate()
                        timer = nil
                    }
                }
            })
            .do(onNext: { _ in
                self.btnLove.setTitleColor(UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
                self.showAnimation()
                self.btnLove.setImage(UIImage.init(named: "h"), for: .normal)
                if self.userReactCount < UserReaction.MAX {
                    self.userReactCount += 1
                    self.reactCount += 1
                    print("USER REACT COUNT:\(self.userReactCount) INCREASE BY:\(self.reactCount)")
                    self.showReactionCount()
                    var post = self.post.value
                    post?.summary.reactCount += self.reactCount
                    self.contentPostView.numberHeartLabel.text = "\(post?.summary.reactCount ?? 0)"
                }
                self.showReactionCount()
            })
                .filter { t in t == nil || self.reactCount == 5}
                .do(onNext: { timer in
                    timer?.invalidate()
                })
            .bind { [weak self] (_) in
                if self!.userReactCount <= UserReaction.MAX {
                    self?.likeEvent?(.love,self?.reactCount ?? 0)
                }
                self?.reactCount = 0
            }
            .disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.btnLove.rx.tap.asObservable(),Observable.just(self.contentPostView) , Observable.just(self))
            .do(onNext: { (arg) in
                if (arg.2.btnLove.imageView?.image == UIImage(named: "h")) {
                    self.giveAction?()
                }
            })
            .filter({ (_, _, view) in
                return view.btnLove.imageView?.image != UIImage(named: "h")
            })
            .do(onNext: { (_,view,vc) in
                guard Session.shared.isAuthenticated else {
                    HandleError.default.loginAlert()
                    return
                }
                self.btnLove.setTitleColor(UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
                self.showAnimation()
                self.btnLove.setImage(UIImage.init(named: "h"), for: .normal)
                if vc.userReactCount < UserReaction.MAX {
                    vc.userReactCount += 1
                    vc.reactCount += 1
                    print("USER REACT COUNT:\(vc.userReactCount) INCREASE BY:\(vc.reactCount)")
                    self.showReactionCount()
                    var post = vc.post.value
                    post?.summary.reactCount += self.reactCount
                    view?.numberHeartLabel.text = "\(post?.summary.reactCount ?? 0)"
                }
                self.showReactionCount()
            })
        .filter { _ in Session.shared.isAuthenticated }
//        .flatMap { (_) -> Observable<Timer> in
//            timer?.invalidate()
//            timer = nil
//            return Observable<Timer>.create { (observer) -> Disposable in
//                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
//                    observer.onNext(timer)
//                })
//                return Disposables.create {
//                    timer?.invalidate()
//                    timer = nil
//                }
//            }
//        }
        .bind { [weak self] (_) in
            if self!.userReactCount <= UserReaction.MAX {
                self?.likeEvent?(.love,self?.reactCount ?? 0)
            }
            self?.reactCount = 0
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func tapBtnComment(){
        self.btnComment.rx.tap.withLatestFrom(self.post.asObservable()).compactMap { $0 }
        .subscribe(onNext: { [weak self] (post) in
            self?.commentEvent?(post)
        })
        .disposed(by: self.disposeBag)
        
        self.btnComment.rx.tapGesture().when(.recognized)
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
