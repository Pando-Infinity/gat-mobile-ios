//
//  ChallengeContentCell.swift
//  gat
//
//  Created by Hung Nguyen on 2/1/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class ChallengeContentCell: UITableViewCell {
    
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbNumMember: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    
    @IBOutlet weak var vAllMems: UIView!
    @IBOutlet weak var ivAvatarMem1: UIImageView!
    @IBOutlet weak var ivAvatarMem2: UIImageView!
    @IBOutlet weak var ivAvatarMem3: UIImageView!
    @IBOutlet weak var ivAvatarMem4: UIImageView!
    @IBOutlet weak var ivAvatarMem5: UIImageView!
    
    @IBOutlet weak var lbNameAllMems: UILabel!
    
    @IBOutlet weak var lbTarget: UILabel!
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var btnReadMore: UIButton!
    
    @IBOutlet weak var vCreator: UIView!
    @IBOutlet weak var ivCreator: UIImageView!
    @IBOutlet weak var lbCreatorName: UILabel!
    
    @IBOutlet weak var icTargetImg:UIImageView!
    @IBOutlet weak var icTrophyImg:UIImageView!
    
    @IBOutlet weak var collectionViewBookTarget:UICollectionView!
    
    
    @IBOutlet weak var constraitWhenClvDisappear: NSLayoutConstraint!
    @IBOutlet weak var constraitWhenClvAppear: NSLayoutConstraint!
    
    @IBOutlet weak var btnInvite:UIButton!
    @IBOutlet weak var progressView:ProgressCircle!
    @IBOutlet weak var miniProgressCircle:ProgressCircle!
    @IBOutlet weak var lbProgressPercent:UILabel!
    
    private var isExpandText: Bool = false
    private var nibListBookTarget:UINib!
    
    private var activeMembers: [LeaderBoard] = []
    var showUser: ((UserPublic) -> Void)?
    var isTappedBtnInvite: ((Bool) -> Void)?
    var openBookTargetPopUpWhenTapCollection: ((Bool) -> Void)?
    var isJoinedChallenge:Bool = false
    
    private var challenge:Challenge? = nil
    
    private var creator: Creator? = nil
    
    var estimateWidth = 80.0
    var cellMarginSize = 4.0
    // Default min lines of label description
    private let defaultMinLines = 3
    
    @IBAction func onSeeMore(_ sender: Any) {
        isExpandText = !isExpandText
        if isExpandText {
            lbDescription.numberOfLines = 0
            btnReadMore.setTitle("SHOW_LESS".localized(), for: .normal)
            SwiftEventBus.post(UpdateChallengeCellHeightEvent.EVENT_NAME, sender: UpdateChallengeCellHeightEvent(true))
        } else {
            lbDescription.numberOfLines = 3
            btnReadMore.setTitle("SHOW_MORE".localized(), for: .normal)
            SwiftEventBus.post(UpdateChallengeCellHeightEvent.EVENT_NAME, sender: UpdateChallengeCellHeightEvent(false))
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set localize
        btnReadMore.setTitle("SHOW_MORE".localized(), for: .normal)
        
        //cornerBtnInvite
        btnInvite.cornerRadius = 4.0
        self.btnInvite.setImage(UIImage.init(named: "plus"), for: .normal)
        self.btnInvite.setTitle(" "+"INVITE_TITLE".localized(), for: .normal)
        
        //init collection view
        self.initCollectionView()
        
        //default hide collection target book
        self.collectionViewBookTarget.isHidden = true
        
        //default hide progress
        self.progressView.isHidden = true
        self.miniProgressCircle.isHidden = true
        
        self.setUpCircle()
    }
    
    fileprivate func initCollectionView(){
        nibListBookTarget = UINib(nibName: "BookTargetChallengeCollectionViewCell", bundle: nil)
        self.collectionViewBookTarget.register(nibListBookTarget, forCellWithReuseIdentifier: "BookTargetChallengeCollectionViewCell")
        
        // Set delegate
        collectionViewBookTarget.delegate = self
        collectionViewBookTarget.dataSource = self
        collectionViewBookTarget.backgroundColor = UIColor(red: 241.0/255.0, green: 245.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        collectionViewBookTarget.cornerRadius(radius: 4.0)
        let widthClv = self.collectionViewBookTarget.frame.width
        let widthCell = widthClv * 0.18
        let space = (widthClv - widthCell * 5)/6
        collectionViewBookTarget.contentInset.right = space
        collectionViewBookTarget.contentInset.left = space
        collectionViewBookTarget.isScrollEnabled = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 16.0, height: 16.0))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    @IBAction func didTapInvite(_ sender: Any) {
        self.isTappedBtnInvite?(true)
    }
    
    func receivedData(challenge: Challenge?){
        self.challenge = challenge
        self.collectionViewBookTarget.reloadData()
    }
    
    func changeUIWhenCollectionViewHidden(){
        //challenge fixed book
        if challenge?.targetTypeId == 3 {
            self.constraitWhenClvAppear.priority = .defaultHigh
            self.constraitWhenClvDisappear.priority = .defaultLow
        } else {
            self.constraitWhenClvAppear.priority = .defaultLow
            self.constraitWhenClvDisappear.priority = .defaultHigh
        }
    }
    
    func setUpCircle(){
        self.progressView.backgroundColor = .white
        self.progressView.trackColor = UIColor.lightGray
        self.progressView.progressColor = UIColor.yellow
        self.progressView.progressLineWidth = 2.0
        self.progressView.trackLineWidth = 2.0
        
        self.miniProgressCircle.backgroundColor = .white
        self.miniProgressCircle.trackColor = UIColor.lightGray
        self.miniProgressCircle.progressColor = UIColor.yellow
        self.miniProgressCircle.progressLineWidth = 1.5
        self.miniProgressCircle.trackLineWidth = 1.5
    }
    
    func setUpProgressView(challenge: Challenge?){
        if challenge?.challengeModeId == 2 {
            self.progressView.isHidden = false
            let progressNum = challenge?.challengeProgress?.progress ?? 0
            let targetNum = challenge?.challengeProgress?.targetNumber ?? 0
            let flagCheckZero = targetNum != 0
            let progressFloat = flagCheckZero ? CGFloat(progressNum / targetNum) : 0
            let percent = Int(progressFloat*100)
            self.lbProgressPercent.text = "\(percent)%"
            self.progressView.progressLayer.strokeEnd = progressFloat
            
            
            //setup mini progress circle
            self.miniProgressCircle.isHidden = false
            self.icTargetImg.image = UIImage()
            self.miniProgressCircle.progressLayer.strokeEnd = progressFloat
            self.lbDescription.text = String(format: "PROGRESS_CIRCLE_TITLE".localized(), progressNum,targetNum,percent)
            self.lbDescription.font = UIFont.boldSystemFont(ofSize: 14.0)
            self.btnReadMore.isHidden = true
        } else {
            self.progressView.isHidden = true
        }
    }


    func setData(challenge: Challenge?) {
//        guard let it = challenge else {
//            return
//        }
//
        // Hide view All members in case user not login yet
        if !Session.shared.isAuthenticated {
            vAllMems.visiblity(gone: true)
        }
        
        //challenge fixed book
        if challenge?.targetTypeId == 3 {
            self.collectionViewBookTarget.isHidden = false
        } else {
            self.collectionViewBookTarget.isHidden = true
        }
        
        self.changeUIWhenCollectionViewHidden()
        
        // Set data for Creator
        self.creator = challenge?.creator
        
        lbTitle.text = challenge?.title
        //print("title height: \(self.lbTitle.frame.height)")
        lbNumMember.text = String(format: "NUMBER_MEM_CHALLENGE".localized(), arguments: [challenge?.challengeSummary?.totalJoiner ?? 0])
        lbTime.text = TimeUtils.getTimeDuration(challenge?.startDate ?? .init(), challenge?.endDate ?? .init())
        
        let duration = TimeUtils.getDayDuration(challenge?.startDate ?? .init(), challenge?.endDate ?? .init())
        if let progress = challenge?.challengeProgress {
            lbTarget.text = String(format: "FORMAT_TARGET_CHALLENGE".localized(),
            progress.targetNumber, duration)
        } else {
            lbTarget.text = String(format: "FORMAT_TARGET_CHALLENGE".localized(),
            challenge?.targetNumber ?? 0, duration)
        }
//        if challenge?.targetTypeId == 2 {
//            lbTarget.text = String(format: "FORMAT_TARGET_CHALLENGE".localized(),
//            challenge?.targetNumber ?? 0, duration)
//        } else {
//        lbTarget.text = String(format: "FORMAT_TARGET_CHALLENGE".localized(),
//                               challenge?.challengeProgress?.targetNumber ?? 0, duration)
//        }
        lbDescription.text = challenge?.description
        print("number of lines: \(lbDescription.maxNumberOfLines)")
        if lbDescription.maxNumberOfLines <= defaultMinLines {
            btnReadMore.isHidden = true
        } else {
            btnReadMore.isHidden = false
        }
        
        // Set data for Creator
        ivCreator.setCircleWithBorder(imageId: challenge?.creator?.imageId ?? "")
        let creatorName = challenge?.creator?.name ?? ""
        lbCreatorName.text = String(format: "CHALLENGE_CREATOR".localized(), arguments: [creatorName])
    }
    
    private func calculateTitleHeight() {
        
    }
    
    func setOnClickListener() {
        self.vAllMems.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                SwiftEventBus.post(
                    OpenChallengeMembersEvent.EVENT_NAME,
                    sender: OpenChallengeMembersEvent(true)
                )
            })
        .disposed(by: disposeBag)
        
        self.lbNameAllMems.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                print("tapGesture called")
                SwiftEventBus.post(
                    OpenChallengeMembersEvent.EVENT_NAME,
                    sender: OpenChallengeMembersEvent(true)
                )
            })
        .disposed(by: disposeBag)
        
        self.vCreator.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                print("vCreator called")
                if let it = self.creator, it.userTypeFlag != 4 {
                    let userPublic = UserPublic()
                    userPublic.profile.id = it.id
                    userPublic.profile.name = it.name
                    userPublic.profile.imageId = it.imageId
                    self.showUser?(userPublic)
                }
            })
        .disposed(by: disposeBag)
    }
    
    func setMembers(leaderBoards: [LeaderBoard]) {
        self.vAllMems.isHidden = leaderBoards.isEmpty
        
        if leaderBoards.count == 0 {
            self.btnInvite.leadingAnchor.constraint(equalTo: self.lbTitle.leadingAnchor).isActive = true
            self.btnInvite.trailingAnchor.constraint(equalTo: self.lbTitle.trailingAnchor).isActive = true
            self.btnInvite.setTitle(" "+"INVITE_FRIEND_TO_JOIN_TITLE".localized(), for: .normal)
        }
        
        switch leaderBoards.count {
        case 0:
            self.vAllMems.isHidden = true
            
        case 1:
            self.ivAvatarMem1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.lbNameAllMems.text = String(
                format: "ONE_MEMBERS_IS_FRIEND_JOINNED".localized(),
                getLastName(fullName: leaderBoards[0].user?.name ?? "")
            )
            
        case 2:
            self.ivAvatarMem1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.ivAvatarMem2.setCircleWithBorder(imageId: leaderBoards[1].user?.imageId ?? "")
            
            self.lbNameAllMems.text = String(
                format: "TWO_MEMBERS_IS_FRIEND_JOINNED".localized(),
                getLastName(fullName: leaderBoards[0].user?.name ?? ""),
                getLastName(fullName: leaderBoards[1].user?.name ?? "")
            )
            
        case 3:
            self.ivAvatarMem1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.ivAvatarMem2.setCircleWithBorder(imageId: leaderBoards[1].user?.imageId ?? "")
            self.ivAvatarMem3.setCircleWithBorder(imageId: leaderBoards[2].user?.imageId ?? "")
            
            self.lbNameAllMems.text = String(
                format: "THREE_MEMBERS_IS_FRIEND_JOINNED".localized(),
                getLastName(fullName: leaderBoards[0].user?.name ?? ""),
                getLastName(fullName: leaderBoards[1].user?.name ?? ""),
                getLastName(fullName: leaderBoards[2].user?.name ?? "")
            )
            
        case 4:
            self.ivAvatarMem1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.ivAvatarMem2.setCircleWithBorder(imageId: leaderBoards[1].user?.imageId ?? "")
            self.ivAvatarMem3.setCircleWithBorder(imageId: leaderBoards[2].user?.imageId ?? "")
            self.ivAvatarMem4.setCircleWithBorder(imageId: leaderBoards[3].user?.imageId ?? "")
            
            self.lbNameAllMems.text = String(
                format: "FOUR_MEMBERS_IS_FRIEND_JOINNED".localized(),
                getLastName(fullName: leaderBoards[0].user?.name ?? ""),
                getLastName(fullName: leaderBoards[1].user?.name ?? ""),
                getLastName(fullName: leaderBoards[2].user?.name ?? ""),
                getLastName(fullName: leaderBoards[3].user?.name ?? "")
            )
            
        case 5:
            self.ivAvatarMem1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.ivAvatarMem2.setCircleWithBorder(imageId: leaderBoards[1].user?.imageId ?? "")
            self.ivAvatarMem3.setCircleWithBorder(imageId: leaderBoards[2].user?.imageId ?? "")
            self.ivAvatarMem4.setCircleWithBorder(imageId: leaderBoards[3].user?.imageId ?? "")
            self.ivAvatarMem5.setCircleWithBorder(imageId: leaderBoards[4].user?.imageId ?? "")
            
            self.lbNameAllMems.text = String(
                format: "MEMBERS_IS_FRIEND_JOINNED_SHORT".localized(),
                getLastName(fullName: leaderBoards[0].user?.name ?? ""),
                getLastName(fullName: leaderBoards[1].user?.name ?? ""),
                getLastName(fullName: leaderBoards[2].user?.name ?? ""),
                getLastName(fullName: leaderBoards[3].user?.name ?? ""),
                getLastName(fullName: leaderBoards[4].user?.name ?? "")
            )
            
        default:
            self.ivAvatarMem1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.ivAvatarMem2.setCircleWithBorder(imageId: leaderBoards[1].user?.imageId ?? "")
            self.ivAvatarMem3.setCircleWithBorder(imageId: leaderBoards[2].user?.imageId ?? "")
            self.ivAvatarMem4.setCircleWithBorder(imageId: leaderBoards[3].user?.imageId ?? "")
            self.ivAvatarMem5.setCircleWithBorder(imageId: leaderBoards[4].user?.imageId ?? "")
            
            self.lbNameAllMems.text = String(
                format: "MEMBERS_IS_FRIEND_JOINNED_LONG".localized(),
                getLastName(fullName: leaderBoards[0].user?.name ?? ""),
                getLastName(fullName: leaderBoards[1].user?.name ?? ""),
                getLastName(fullName: leaderBoards[2].user?.name ?? ""),
                getLastName(fullName: leaderBoards[3].user?.name ?? ""),
                (leaderBoards.count - 4)
            )
        }
    }
    
    private func getLastName(fullName: String) -> String {
        let fullNameArr = fullName.split(separator: " ")
        let lastName = fullNameArr.count > 0 ? fullNameArr[fullNameArr.count - 1] : ""
        return String(lastName)
    }
    
    @IBAction func onSeeallActiveMembers(_ sender: Any) {
        // Send event back to main scence to open list active mebers
        print("Send event ")
        SwiftEventBus.post(
            OpenChallengeMembersEvent.EVENT_NAME,
            sender: OpenChallengeMembersEvent(false)
        )
    }
}

extension ChallengeContentCell {
    
    class func getSize(lbWidth: CGFloat, text: String, lines: Int) -> CGFloat {
        //let width = self.lb.frame.width - 32.0
        let title = UILabel()
        title.text = text
        title.font = .systemFont(ofSize: 14.0, weight: .regular)
        title.numberOfLines = lines
        let realWidth = lbWidth - 38
        let sizeTitle = title.sizeThatFits(.init(width: realWidth, height: .infinity))
        print("size when extend: \(sizeTitle)")
        return sizeTitle.height
    }

    class func getTitleHeight(lbWidth: CGFloat, text: String, lines: Int) -> CGFloat {
        let title = UILabel()
        title.text = text
        title.font = .systemFont(ofSize: 18.0, weight: .semibold)
        title.numberOfLines = lines
        let realWidth = lbWidth //- 38
        let sizeTitle = title.sizeThatFits(.init(width: realWidth, height: .infinity))
        print("Height title: \(sizeTitle)")
        return sizeTitle.height
    }
}

extension ChallengeContentCell:UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("TAPPPP")
        if self.isJoinedChallenge == true {
            self.openBookTargetPopUpWhenTapCollection?(false)
        } else {
            self.openBookTargetPopUpWhenTapCollection?(true)
        }
    }
}

extension ChallengeContentCell:UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.challenge?.editions?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookTargetChallengeCollectionViewCell", for: indexPath) as! BookTargetChallengeCollectionViewCell
        let challengeCell = self.challenge
        let bookArr = challengeCell?.editions
        let book = bookArr![indexPath.row]
        let img = book.imageId
        cell.imgBook.contentMode = .scaleToFill
        cell.imgBook.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: img )), placeholderImage: DEFAULT_BOOK_ICON)
        cell.lbNumberBookRest.isHidden = true
        if indexPath.row == 4 {
            cell.imgBook.image = cell.imgBook.image?.blurred(radius: 10.0)
            let editionCount = self.challenge?.editions?.count ?? 0
            cell.lbNumberBookRest.isHidden = false
            cell.lbNumberBookRest.text = "+\(editionCount-4)"
        }
        return cell
    }
}

extension ChallengeContentCell:UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let heightClv = self.collectionViewBookTarget.frame.height
        let widthClv = self.collectionViewBookTarget.frame.width
        let width:CGFloat = widthClv * 0.18
        let height = heightClv - 16.0
        return CGSize(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let widthClv = self.collectionViewBookTarget.frame.width
        let widthCell = widthClv * 0.18
        let space = (widthClv - widthCell * 5)/6
        return space
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
}


extension UIImage {
    func blurred(radius: CGFloat) -> UIImage {
        let ciContext = CIContext(options: nil)
        guard let cgImage = cgImage else { return self }
        let inputImage = CIImage(cgImage: cgImage)
        guard let ciFilter = CIFilter(name: "CIGaussianBlur") else { return self }
        ciFilter.setValue(inputImage, forKey: kCIInputImageKey)
        ciFilter.setValue(radius, forKey: "inputRadius")
        guard let resultImage = ciFilter.value(forKey: kCIOutputImageKey) as? CIImage else { return self }
        guard let cgImage2 = ciContext.createCGImage(resultImage, from: inputImage.extent) else { return self }
        return UIImage(cgImage: cgImage2)
    }
}
