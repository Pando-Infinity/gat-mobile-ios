//
//  InfoBookstopView.swift
//  gat
//
//  Created by Vũ Kiên on 16/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol InfoBookstopDelegate: class {
    func showBookstop(identifier: String, sender: Any?)
}

class InfoBookstopView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameBookstopLabel: UILabel!
    @IBOutlet weak var memberTitleLabel: UILabel!
    @IBOutlet weak var numberMembersLabel: UILabel!
    @IBOutlet weak var numberBooksLabel: UILabel!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    weak var delegate: InfoBookstopDelegate?
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.bookstop
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.setup(info: bookstop.profile!)
                let kind = bookstop.kind as? BookstopKindOrganization
                self?.numberBooksLabel.text = "\(kind?.totalEdition ?? 0)"
                self?.numberMembersLabel.text = "\(kind?.totalMemeber ?? 0)"
            })
            .disposed(by: self.disposeBag)
        self.memberTitleLabel.text = Gat.Text.RequestBorrowerBookstop.MEMBERS_TITLE.localized()
        self.bookTitleLabel.text = Gat.Text.RequestBorrowerBookstop.BOOKS_TITLE.localized()
    }
    
    fileprivate func setup(info: Profile) {
        self.layoutIfNeeded()
        self.imageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: info.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.imageView.circleCorner()
        self.nameBookstopLabel.text = info.name
        self.aboutLabel.text = info.about
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.imageView
            .rx
            .tapGesture()
            .when(.recognized)
            .withLatestFrom(self.bookstop)
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.delegate?.showBookstop(identifier: "showBookstopOrganization", sender: bookstop)
            })
            .disposed(by: self.disposeBag)
    }

}
