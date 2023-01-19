//
//  ActivityPostFooterCollectionReusableView.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Lottie

class ActivityPostFooterCollectionReusableView: UICollectionReusableView {
    
    class var identifier: String { "activityPostFooter" }
    
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var heartTitleLabel: UILabel!
    @IBOutlet weak var heartView: UIView!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentTitleLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    
    let isReaction: BehaviorRelay<Bool> = .init(value: false)
    var commentHandler: (() -> Void)?
    var reactionHandler: ((Post.Reaction, Int) -> Observable<()>)?
    var updateReactionWhenInteracing: ((UserReaction) -> Void)?
    var giveAction: (() -> Void)?
    
    fileprivate var reactionCount = 0
    var userReactCount:Int = 0
    var postReactCount:Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.heartTitleLabel.isUserInteractionEnabled = true
        self.commentTitleLabel.isUserInteractionEnabled = true
        self.layer.masksToBounds = false
        self.isReaction.map { $0 ? #imageLiteral(resourceName: "h") : #imageLiteral(resourceName: "heart") }.bind(to: self.heartButton.rx.image()).disposed(by: self.disposeBag)
        self.isReaction.asObservable().subscribe(onNext: { (like) in
            let color = like ? UIColor.init(red: 224.0/255.0, green: 90.0/255.0, blue: 90.0/255.0, alpha: 1.0) : UIColor.brownGrey
            self.heartTitleLabel.textColor = color
        }).disposed(by: self.disposeBag)
        self.commentTitleLabel.text = "COMMENT_POST_TITTLE".localized()
        self.heartTitleLabel.text = "LOVE_POST_TITLE".localized()
        self.event()
    }
    
    fileprivate func showAnimation() {
        let animationView = AnimationView(name: "heart")
        animationView.animationSpeed = 0.5
        animationView.backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        self.heartView.insertSubview(animationView, belowSubview: self.heartButton)
        animationView.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.heartButton.snp.centerX)
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
        
        self.heartView.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.heartButton.snp.centerX)
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
    
    // MARK: - Event
    fileprivate func event() {
        Observable.of(self.commentButton.rx.tap.asObservable(), self.commentTitleLabel.rx.tapGesture().when(.recognized).map { _ in })
            .merge()
            .do(onNext: {  (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .bind { [weak self] in
            self?.commentHandler?()
        }
        .disposed(by: self.disposeBag)
        
        
        var timer: Timer?

//        self.heartButton.rx.controlEvent(.touchDown).asObservable()
//            .do { (_) in
//                guard !Session.shared.isAuthenticated else { return }
//                HandleError.default.loginAlert()
//            }.filter { _ in Session.shared.isAuthenticated }
//            .do { [weak self] (_) in
//                self?.showAnimation()
//                self?.heartButton.setImage(#imageLiteral(resourceName: "h"), for: .normal)
//                timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true, block: { (_) in
//                    self?.showAnimation()
//                    guard let cell = self, cell.userReactCount < UserReaction.MAX else {
//                        self?.showReactionCount()
//                        timer?.invalidate()
//                        timer = nil
//                        return
//                    }
//                    cell.userReactCount += 1
//                    cell.reactionCount += 1
//                    self?.showReactionCount()
//
//                    cell.updateReactionWhenInteracing?(UserReaction(reactionId: Post.Reaction.love.rawValue, reactCount: 1))
//                })
//                self?.showReactionCount()
//            }.withLatestFrom(self.isReaction.asObservable())
//            .flatMap({ [weak self] (reaction) -> Observable<()> in
//                guard let obs = self?.reactionHandler?(.love, self?.reactionCount ?? 0) else { return .empty() }
//                self?.reactionCount = 0
//                return obs.catchError { (error) -> Observable<()> in
//                    if !reaction {
//                        self?.heartButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
//                    }
//                    return .empty()
//                }
//            })
//            .subscribe()
//            .disposed(by: self.disposeBag)
        Observable.of(
            self.heartTitleLabel.rx.longPressGesture().when(.ended),
            self.heartButton.rx.longPressGesture().when(.ended)
        )
        .merge()
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
        .withLatestFrom(self.isReaction.asObservable())
        .flatMap({ [weak self] (reaction) -> Observable<()> in
            guard let obs = self?.reactionHandler?(.love, self?.reactionCount ?? 0) else { return .empty() }
            self?.reactionCount = 0
            return obs.catchError { (error) -> Observable<()> in
                if !reaction {
                    self?.heartButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                }
                return .empty()
            }
        })
        .subscribe()
        .disposed(by: self.disposeBag)
        

        Observable.of(
            self.heartTitleLabel.rx.longPressGesture().when(.began, .ended),
            self.heartButton.rx.longPressGesture().when(.began, .ended)
        )
        .merge()
        .do(onNext: {  (_) in
            guard !Session.shared.isAuthenticated else { return }
            HandleError.default.loginAlert()
        })
        .filter { _ in Session.shared.isAuthenticated }
        .filter({ _ in
            return !self.isReaction.value
        })
        .flatMap({ gesture -> Observable<Timer?> in
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
        .do(onNext: { [weak self] t in
            guard t != nil else { return }
            self?.showAnimation()
            self?.heartButton.setImage(#imageLiteral(resourceName: "h"), for: .normal)
            guard let cell = self, cell.userReactCount < UserReaction.MAX else {
                self?.showReactionCount()
                return
            }
            cell.userReactCount += 1
            cell.reactionCount += 1
            self?.showReactionCount()

            cell.updateReactionWhenInteracing?(UserReaction(reactionId: Post.Reaction.love.rawValue, reactCount: 1))
        })
            .filter { t in t == nil || self.reactionCount == 5}
            .do(onNext: { timer in
                timer?.invalidate()
            })
        .withLatestFrom(self.isReaction.asObservable())
        .flatMap({ [weak self] (reaction) -> Observable<()> in
            guard let obs = self?.reactionHandler?(.love, self?.reactionCount ?? 0) else { return .empty() }
            self?.reactionCount = 0
            return obs.catchError { (error) -> Observable<()> in
                if !reaction {
                    self?.heartButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                }
                return .empty()
            }
        })
        .subscribe()
        .disposed(by: self.disposeBag)
            

        
        Observable.of(
            self.heartButton.rx.tap.asObservable(),
            self.heartTitleLabel.rx.tapGesture().when(.recognized).map { _ in }
        )
        .merge()
            .do(onNext: {  (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .do(onNext: { _ in
                if (self.isReaction.value) {
                    self.giveAction?()
                }
            })
            .filter({ _ in
                return !self.isReaction.value
            })
            .do (onNext: { [weak self] (_) in
                self?.showAnimation()
                self?.heartButton.setImage(#imageLiteral(resourceName: "h"), for: .normal)
                guard let cell = self, cell.userReactCount < UserReaction.MAX else {
                    self?.showReactionCount()
                    return
                }
                cell.userReactCount += 1
                cell.reactionCount += 1
                self?.showReactionCount()

                cell.updateReactionWhenInteracing?(UserReaction(reactionId: Post.Reaction.love.rawValue, reactCount: 1))
            })
//            .flatMap { (_) -> Observable<Timer> in
//                timer?.invalidate()
//                timer = nil
//                return Observable<Timer>.create { (observer) -> Disposable in
//                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
//                        observer.onNext(timer)
//                    })
//                    return Disposables.create {
//                        timer?.invalidate()
//                        timer = nil
//                    }
//                }
//            }
            .withLatestFrom(self.isReaction.asObservable())
            .flatMap({ [weak self] (reaction) -> Observable<()> in
                guard let obs = self?.reactionHandler?(.love, self?.reactionCount ?? 0) else { return .empty() }
                self?.reactionCount = 0
                return obs.catchError { (error) -> Observable<()> in
                    if !reaction {
                        self?.heartButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                    }
                    return .empty()
                }
            })
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
}

extension ActivityPostFooterCollectionReusableView {
    class func size(in bounds: CGSize) -> CGSize {
        return .init(width: bounds.width, height: 48.0)
    }
}
