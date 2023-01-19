//
//  BookTargetReadingProgressTableViewCell.swift
//  gat
//
//  Created by macOS on 8/25/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import GradientProgressBar
import RxSwift
import RxCocoa

class BookTargetReadingProgressTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgBook:UIImageView!
    @IBOutlet weak var lbNameBook:UILabel!
    @IBOutlet weak var lbNameAuthor:UILabel!
    @IBOutlet weak var btnStartReading:UIButton!
    @IBOutlet weak var lbSuggest:UILabel!
    @IBOutlet weak var lbProgress:UILabel!
    @IBOutlet weak var progress:GradientProgressBar!
    @IBOutlet weak var progressContainerView:UIView!
    @IBOutlet weak var imgComplete:UIImageView!
    
    @IBOutlet weak var viewReadingWhenNotInProgress: NSLayoutConstraint!
    
    @IBOutlet weak var viewReadingWhenInProgress: NSLayoutConstraint!
    
    var reading:Reading! = Reading()
    let book: BehaviorRelay<Book> = .init(value: .init())
    let disposeBag = DisposeBag()
    var startHandle: ((Reading) -> Void)?
    var tapImgBook:((Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.imgBook.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { (_) in
                self.tapImgBook?(true)
            }).disposed(by: self.disposeBag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func setupUI(){
        self.setUpCorner()
        self.btnStartReading.setTitle("START_READING_TITLE".localized(), for: .normal)
    }
    
    func setUIByStatusReading(reading:Reading?){
        if reading?.readingStatusId == 0 { //done
            self.imgComplete.isHidden = false
            self.contentView.bringSubviewToFront(self.imgComplete)
            self.progressContainerView.isHidden = true
            self.btnStartReading.isHidden = true
            self.lbSuggest.isHidden = true
            if self.progressContainerView.isHidden == false {
                self.viewReadingWhenInProgress.priority = .defaultHigh
                self.viewReadingWhenNotInProgress.priority = .defaultLow
            }
        } else if reading?.readingId == -1 { //not read
            self.imgComplete.isHidden = true
            self.progressContainerView.isHidden = true
            self.btnStartReading.isHidden = false
            self.contentView.bringSubviewToFront(self.btnStartReading)
            self.lbSuggest.isHidden = false
            self.lbSuggest.text = "ADD_TO_READING_LIST_TITLE".localized()
            if self.progressContainerView.isHidden == false {
                self.viewReadingWhenInProgress.priority = .defaultHigh
                self.viewReadingWhenNotInProgress.priority = .defaultLow
            }
        }
        else if reading?.readingStatusId == 1 { //reading
            self.imgComplete.isHidden = true
            self.progressContainerView.isHidden = false
            self.btnStartReading.isHidden = true
            self.lbSuggest.textAlignment = .left
            if self.progressContainerView.isHidden == false {
                self.viewReadingWhenInProgress.priority = .defaultHigh
                self.viewReadingWhenNotInProgress.priority = .defaultLow
            }
            let date = TimeUtils.getDateFromString(reading!.startDate)
            if let it = date {
                self.lbSuggest.text = String(format: "FORMAT_READ_FROM_TIME_AGO".localized(), AppConfig.sharedConfig.calculatorDay(date: it))
            }
        }
    }
    
    func setUpCorner(){
        self.imgBook.cornerRadius(radius: 4.0)
        self.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
        self.btnStartReading.cornerRadius(radius: 4.0)
        self.btnStartReading.layer.borderWidth = 1.0
        self.btnStartReading.layer.borderColor = UIColor.init(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0).cgColor
    }
    
     func setupProgressBar(reading:Reading) {
        self.progress.gradientColors = [#colorLiteral(red: 0.3058823529, green: 0.7019607843, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.5254901961, green: 0.6509803922, blue: 0.8549019608, alpha: 1)]
        self.progress.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        self.progress.cornerRadius(radius: 12.0)
        self.progress.layer.borderColor = #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 0.19)
        self.progress.layer.borderWidth = 1.0
        
        //self.progressBar.progress = 0.8
        self.progress.progress = Float(reading.readPage) / Float(reading.pageNum)
        self.lbProgress.text = "\(reading.readPage)/\(reading.pageNum)"
    }
    
    @IBAction func onStartReadingBook(_ sender: Any) {
        print("Data when add book: \(self.book.value.editionId)")
        self.startHandle?(self.reading)
    }
    
}
