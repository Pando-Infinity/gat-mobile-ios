//
//  CreateArticleAlertViewController.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class CreateArticleAlertViewController: BottomPopupViewController {
    
    class var identifier: String { Self.className }
    
    override var popupHeight: CGFloat {
        if #available(iOS 11.0, *) {
            return 170.0 + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0)
        }
        return 170.0
        
    }
    
    override var popupTopCornerRadius: CGFloat { return 10.0 }
    
    override var popupPresentDuration: Double { return  0.3 }
    
    override var popupDismissDuration: Double { return 0.3 }
    
    override var popupShouldDismissInteractivelty: Bool { return true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
    
    @IBOutlet weak var tableView: UITableView!
    fileprivate let disposeBag = DisposeBag()
    var select: ((Item) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.tableView.rowHeight = 170.0 / CGFloat(Item.allCases.count)
        Observable.just(Item.allCases)
            .bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { (index, item, cell) in
                cell.textLabel?.text = item.title
                if index == Item.continue.rawValue {
                    cell.textLabel?.textColor = .fadedBlue
                    cell.textLabel?.font = .systemFont(ofSize: 18.0, weight: .bold)
                } else {
                    cell.textLabel?.font = .systemFont(ofSize: 18.0)
                    cell.textLabel?.textColor = .navy
                }
        }
        .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.tableView.rx.modelSelected(Item.self)
            .subscribe(onNext: { [weak self] (item) in
                self?.dismiss(animated: true, completion: nil)
                self?.select?(item)
                
            })
            .disposed(by: self.disposeBag)
    }
    
    enum Item: Int, CaseIterable {
        case draft = 0
        case `continue` = 1
        case cancel = 2
        
        var title: String {
            switch self {
            case .draft: return "SAVE_DRAFT_TITLE_CREATE_POST".localized()
            case .continue: return "CONTINUE_EDIT_POST_TITLE".localized()
            case .cancel: return "THROW_DRAFT_TITLE".localized()
            }
        }
    }

}
