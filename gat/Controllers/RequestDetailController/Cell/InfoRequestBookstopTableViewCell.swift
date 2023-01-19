//
//  InfoRequestBookstopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 13/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class InfoRequestBookstopTableViewCell: UITableViewCell {

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var boundView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    
    weak var delegate: InfoRequestDetailDelegate?
    var bookRequest: BookRequest?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.event()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.setupUI()
    }
    
    fileprivate func setupUI() {
        self.actionView.circleCorner()
        self.boundView.cornerRadius(radius: self.boundView.frame.height / 2.0)
        self.boundView.layer.borderColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
        self.boundView.layer.borderWidth = 1.5
        self.actionButton.cornerRadius(radius: self.actionButton.frame.height / 2.0)
        
    }
    
    fileprivate func event() {
        self.actionButton
            .rx
            .tap
            .asObservable()
            .flatMapLatest { [weak self] (_) -> Observable<BookRequest> in
                return Observable<BookRequest>.from(optional: self?.bookRequest)
            }
            .subscribe(onNext: { [weak self] (bookRequest) in
                self?.delegate?.handleActionButton(bookRequest: bookRequest, selectStatus: .completed)
            })
            .disposed(by: self.disposeBag)
    }

}
