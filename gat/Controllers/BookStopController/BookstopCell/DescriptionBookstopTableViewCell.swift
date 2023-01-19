//
//  DescriptionBookstopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import ExpandableLabel
import RxSwift

class DescriptionBookstopTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionBookstopLabel: ExpandableLabel!
    
    weak var controller: BookSpaceViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup() {
        self.controller?.bookstopController?
            .bookstop
            .subscribe(onNext: { [weak self] (bookstop) in
                let isEmpty = bookstop.profile?.about.isEmpty
                if let empty = isEmpty, !empty {
                    self?.descriptionBookstopLabel.text = bookstop.profile?.about
                } else {
                    self?.descriptionBookstopLabel.text = " "
                }
            })
            .disposed(by: self.disposeBag)
        //self.descriptionBookstopLabel.text = self.controller?.bookstop.about
        self.descriptionBookstopLabel.numberOfLines = 3
        if let collapsed = self.controller?.isShowMoreDescription {
            self.descriptionBookstopLabel.collapsed = collapsed
        }
        
        self.descriptionBookstopLabel.delegate = self.controller
        self.descriptionBookstopLabel.collapsedAttributedLink = NSAttributedString(string: "more", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
        self.descriptionBookstopLabel.expandedAttributedLink = NSAttributedString(string: "less", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
    }

}
