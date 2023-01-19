//
//  InfoRequestDetailTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 07/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol InfoRequestDetailDelegate: class {
    func handleActionButton(bookRequest: BookRequest, selectStatus: RecordStatus?)
}

class InfoRequestDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var boundView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var actionLeadingLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionLeadingHighConstraint: NSLayoutConstraint!
    
    weak var delegate: InfoRequestDetailDelegate?
    var bookRequest: BookRequest?
    var selectedStatus: RecordStatus?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.setupUI()
    }
    
    fileprivate func setupUI() {
        self.boundView.layer.borderColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
        self.boundView.layer.borderWidth = 1.5
        self.actionButton.cornerRadius(radius: self.actionButton.frame.height / 2.0)
        self.boundView.cornerRadius(radius: self.boundView.frame.height / 2.0)
        self.actionView.circleCorner()
        
    }
    
    func event() {
        self.actionButton
            .rx
            .tap
            .asObservable()
            .flatMapLatest { [weak self] (_) -> Observable<(BookRequest, RecordStatus?)> in
                return Observable<(BookRequest, RecordStatus?)>
                    .combineLatest(
                        Observable<BookRequest>.from(optional: self?.bookRequest),
                        Observable<RecordStatus?>.just(self?.selectedStatus),
                        resultSelector: { ($0, $1) }
                    )
            }
            .subscribe(onNext: { [weak self] (bookRequest, recordStatus) in
                self?.delegate?.handleActionButton(bookRequest: bookRequest, selectStatus: recordStatus)
            })
            .disposed(by: self.disposeBag)
    }

}
