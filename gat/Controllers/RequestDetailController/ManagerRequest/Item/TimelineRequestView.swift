//
//  TimelineRequestView.swift
//  gat
//
//  Created by Vũ Kiên on 04/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class TimelineRequestView: UIView {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var expectationTitleLabel: UILabel!
    @IBOutlet weak var timeExpectationLabel: UILabel!
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    
    let timeline: BehaviorSubject<[(String, Date)]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.expectationTitleLabel.text = Gat.Text.BorrowerRequestDetail.BORROW_EXPECTATION_TIME_TITLE.localized() + ":"
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.registerCell()
        self.tableView.delegate = self
        self.timeline
            .do(onNext: { [weak self] (timeline) in
                if timeline.isEmpty {
                    self?.tableView.frame.size.height = 0.0
                }
            })
            .bind(to: self.tableView.rx.items(cellIdentifier: "timelineCell", cellType: TimelineTableViewCell.self))
            { (index, value, cell) in
                cell.titleDateLabel.text = value.0 + ":"
                cell.dateLabel.text = AppConfig.sharedConfig.stringFormatter(from: value.1, format:                 LanguageHelper.language == .japanese ? "yyyy MM dd" : "MMM dd, yyyy"
)
            }
            .disposed(by: self.disposeBag)
    }
    
    func setupExpectation(time: ExpectedTime) {
        self.timeExpectationLabel.text = time.toString
    }
    
    fileprivate func registerCell() {
        self.tableView.register(UINib(nibName: "TimelineTableViewCell", bundle: nil), forCellReuseIdentifier: "timelineCell")
    }
}

extension TimelineRequestView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let value = try? self.timeline.value(), !value.isEmpty {
            return tableView.frame.height / CGFloat(value.count)
        }
        return 0.0
    }
}
