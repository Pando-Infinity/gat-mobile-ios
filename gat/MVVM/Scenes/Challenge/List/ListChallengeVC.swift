//
//  ListChallengeVC.swift
//  gat
//
//  Created by Frank Nguyen on 1/10/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ListChallengeVC: BaseViewController {
    
    override class var storyboardName: String {return "ListChallengeView"}
    
    class var segueIdentifier: String { "showListChallenge" }
    
//    @IBOutlet weak var vMyChalelnges: UIView!
//    @IBOutlet weak var lbMyChallenges: UILabel!
//    @IBOutlet weak var cvMyChallenges: UICollectionView!
//    @IBOutlet weak var tvChallenges: UITableView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tbChallenges: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    
    private var viewModelChallenges: ChallengesViewModel!
    private var viewModelChallengesGATUP: ChallengeGATUPModel!
    private let useCase = Application.shared.networkUseCaseProvider
    private var input: ChallengesViewModel.Input!
    private var inputGATUP: ChallengeGATUPModel.Input!
    
    private var challenges: [Challenge] = []
    private var myChallenges: [Challenge] = []
    
    private var heightSection0: CGFloat = 0.0
    private var heightCellMyChallenge: CGFloat = 170.0
    
    public var bookstop:BehaviorSubject<Bookstop?> = .init(value: nil)
    
    public var flagChallengeModel:Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init View
        initView()
        
        // Bind ViewModel
        viewModelChallenges = ChallengesViewModel(useCase: useCase.makeChallengesUseCase())
        viewModelChallengesGATUP = ChallengeGATUPModel(useCase: useCase.makeChallengesUseCase())
        
        input = ChallengesViewModel.Input(
            loadTrigger: Driver.just(())
        )
        
        inputGATUP = ChallengeGATUPModel.Input(getBookstop: bookstop)
        
        bindViewModelChallenges()
        
        // Set On EventBus listener
        onOpenChallengeDetailEvent()
        onRefreshDataEvent()
        onOpenReadingsEvent()
        
        LanguageHelper.changeEvent.subscribe(onNext: self.tbChallenges.reloadData).disposed(by: self.disposeBag)
    }
    
    private func setUpTitleLabel(){
        let attachment = NSTextAttachment()
        attachment.image = UIImage.init(named: "trophy")
        // Set bound to reposition
        let imageOffsetY: CGFloat = -4.0
        attachment.bounds = CGRect(x: 0, y: imageOffsetY, width: attachment.image!.size.width, height: attachment.image!.size.height)
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: "")
        myString.append(attachmentString)
        let titleChallenge = NSMutableAttributedString(string: " \("CHALLENGE_TITLE".localized())")
        myString.append(titleChallenge)
        self.titleLabel.textAlignment = .center
        self.titleLabel.attributedText = myString
    }
    
    private func initView() {
        // Init section height
        //self.titleLabel.text = "CHALLENGE_TITLE".localized()
        setUpTitleLabel()
        heightSection0 = 35.0 * tbChallenges.frame.height / 667.0
        // Register my challenge cell
        let myChallengeNib = UINib(nibName: "MyChallengeTableCell", bundle: nil)
        self.tbChallenges.register(myChallengeNib, forCellReuseIdentifier: "MyChallengeTableCell")
        
        // Register chalelnge cell
        let challengeNib = UINib(nibName: "ChallengeCell", bundle: nil)
        self.tbChallenges.register(challengeNib, forCellReuseIdentifier: "ChallengeCell")
        
        // Init TableView
        self.tbChallenges.delegate = self
        self.tbChallenges.dataSource = self
        self.tbChallenges.tableFooterView = UIView()
        //self.tbChallenges.allowsSelection = false
        self.backButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    private func bindViewModelChallenges() {
        
        if flagChallengeModel == 1 {
          let output = viewModelChallenges.transform(input)
          
          output.challenges.drive(challengesBinding)
          .disposed(by: disposeBag)
          
          output.myChallenges.drive(myChallengeBinding)
          .disposed(by: disposeBag)
          
          output.indicator
          .drive(rx.isLoading)
          .disposed(by: disposeBag)
          
          output.error
          .drive(rx.error)
          .disposed(by: disposeBag)
        }
        else if flagChallengeModel == 2 {
            self.setupHeaderTitle(label: titleLabel)
            let output = viewModelChallengesGATUP.transform(inputGATUP)
            
            output.challenges.bind(to: challengesBinding)
            .disposed(by: disposeBag)
            
            output.myChallenges.bind(to: myChallengeBinding)
            .disposed(by: disposeBag)
            
            output.indicator
            .drive(rx.isLoading)
            .disposed(by: disposeBag)
            
            output.error
            .drive(rx.error)
            .disposed(by: disposeBag)
        }
    }
    
    fileprivate func setupHeaderTitle(label: UILabel) {
        self.bookstop.compactMap{ $0!.profile }.map { String(format: "CHALLENGE_GATUP".localized(), $0.name) }.bind(to: label.rx.text).disposed(by: self.disposeBag)
    }
    
    private var challengesBinding: Binder<Challenges> {
        return Binder(self, binding: { (vc, challenges) in
            guard let data = challenges.challenges else { return }
            self.challenges = data
            self.tbChallenges.reloadData()
        })
    }
    
    private var myChallengeBinding: Binder<Challenges> {
        return Binder(self, binding: { (vc, challenges) in
            guard let data = challenges.challenges else {
                self.heightSection0 = 0
                self.heightCellMyChallenge = 0
                self.tbChallenges.reloadData()
                return
            }
            self.myChallenges = data
            (self.tbChallenges.cellForRow(at: IndexPath(row: 0, section: 0)) as? MyChallengeTableCell)?.setData(myChallenges: data)
            self.heightSection0 = 35.0 * self.tbChallenges.frame.height / 667.0
            self.heightCellMyChallenge = 170.0
            self.tbChallenges.reloadData()
        })
    }
    
    private func onOpenChallengeDetailEvent() {
        SwiftEventBus.onMainThread(self, name: OpenChallengeDetailEvent.EVENT_NAME) { result in
            print("onOpenChallengeDetailEvent called")
            let event: OpenChallengeDetailEvent? = result?.object as? OpenChallengeDetailEvent
            if let it = event {
                self.openChallengeDetail(idChallenge: it.challengeId)
            }
        }
    }
    
    private func onRefreshDataEvent() {
        SwiftEventBus.onMainThread(self, name: RefreshChallengesEvent.EVENT_NAME) { result in
            self.bindViewModelChallenges()
        }
    }
    
    private func onOpenReadingsEvent() {
        SwiftEventBus.onMainThread(self, name: OpenReadingsEvent.EVENT_NAME) { result in
            self.openReadings()
        }
    }
    
    private func openChallengeDetail(idChallenge: Int) {
        print("openChallengeDetail called")
        self.performSegue(withIdentifier: "showDetail", sender: idChallenge)
    }
    
    private func openReadings() {
        self.performSegue(withIdentifier: "showReadings", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "showDetail" {
            let vc = segue.destination as? ChallengeDetailVC
            print("data pass segue: \(sender)")
            vc?.idChallenge = sender as! Int
            vc?.hidesBottomBarWhenPushed = true
         }
    }
    
    @IBAction func unwindToListChallenges(_ sender: UIStoryboardSegue) {}
}

extension ListChallengeVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("cell select ar row: \(indexPath.row)")
        if indexPath.row < challenges.count {
            let challenge = self.challenges[indexPath.row]
            openChallengeDetail(idChallenge: challenge.id)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if Session.shared.isAuthenticated && !self.myChallenges.isEmpty {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Session.shared.isAuthenticated && !self.myChallenges.isEmpty {
            if section == 0 {
                return 1
            } else {
                return self.challenges.count
            }
        } else {
            return self.challenges.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if Session.shared.isAuthenticated && !self.myChallenges.isEmpty {
            var cell: UITableViewCell
            if indexPath.section == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "MyChallengeTableCell", for: indexPath) as! MyChallengeTableCell
                (cell as? MyChallengeTableCell)?.initView()
                (cell as? MyChallengeTableCell)?.setData(myChallenges: self.myChallenges)
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell", for: indexPath) as! ChallengeCell
                (cell as? ChallengeCell)?.setData(self.challenges[indexPath.row])
            }
            
            let bgColorView = UIView()
            bgColorView.backgroundColor = .white
            cell.selectedBackgroundView = bgColorView
            return cell
        } else {
            var cell:UITableViewCell
            cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell", for: indexPath) as! ChallengeCell
            (cell as? ChallengeCell)?.setData(self.challenges[indexPath.row])
            return cell
        }
    }
}

extension ListChallengeVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Session.shared.isAuthenticated && !self.myChallenges.isEmpty {
            if indexPath.section == 0 {
                return self.heightCellMyChallenge
            } else {
                return 320.0
            }
        } else {
            return 320.0
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if Session.shared.isAuthenticated {
            let view = Bundle.main.loadNibNamed("HeaderSearch", owner: self, options: nil)?.first as? HeaderSearch
            if section == 0 {
                view?.titleLabel.text = "YOUR_CHALLENGES".localized()
            } else {
                if self.challenges.isEmpty {
                    return UIView()
                } else {
                    view?.titleLabel.text = "CHALLENGES_MAY_WANT_JOY".localized()
                }
                
            }
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            
            
            view?.backgroundColor = .white
            view?.showView.isHidden = true
            return view
            
        } else {
           let view = Bundle.main.loadNibNamed("HeaderSearch", owner: self, options: nil)?.first as? HeaderSearch
            view?.titleLabel.text = "CHALLENGES_MAY_WANT_JOY".localized()
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            
            
            view?.backgroundColor = .white
            view?.showView.isHidden = true
            return view
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if Session.shared.isAuthenticated {
            if section == 0 {
                return self.heightSection0
            } else {
                return 35.0 * tableView.frame.height / 667.0
            }
        } else {
            return 35.0 * tableView.frame.height / 667.0
        }
    }
}
