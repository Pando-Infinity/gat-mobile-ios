//
//  BookSpaceViewController.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import ExpandableLabel
import RxSwift

class BookSpaceViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var height: CGFloat = 0.0
    
    fileprivate let disposeBag = DisposeBag()
    
    weak var bookstopController: BookStopViewController?
    var isShowMoreDescription = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.height = self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height
    }
}

extension BookSpaceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "imageBookstopCell", for: indexPath) as! ImageBookStopTableViewCell
        cell.bookstopSpaceController = self
        cell.setupUI()
        return cell
//        if indexPath.row == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionBookStopCell", for: indexPath) as! DescriptionBookstopTableViewCell
//            cell.controller = self
//            cell.setup()
//            return cell
//        } else if indexPath.row == 1 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "shareSocialCell", for: indexPath) as! ShareSocialTableViewCell
//            cell.controller = self
//            cell.setupUI()
//            return cell
//        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "imageBookstopCell", for: indexPath) as! ImageBookStopTableViewCell
//            cell.bookstopSpaceController = self
//            cell.setupUI()
//            return cell
//        }
    }
}

extension BookSpaceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if indexPath.row == 0 {
//            return UITableViewAutomaticDimension
//        } else if indexPath.row == 1 {
//            return 0.14 * tableView.frame.height
//        } else {
//            return tableView.frame.height - UITableViewAutomaticDimension - 0.14 * tableView.frame.height
//        }
        return tableView.frame.height
    }
}
extension BookSpaceViewController: ExpandableLabelDelegate {
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tableView.beginUpdates()
    }

    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) {
            if self.tableView.cellForRow(at: indexPath) as? DescriptionBookstopTableViewCell != nil {
                self.isShowMoreDescription = !self.isShowMoreDescription
            }
        }
        self.tableView.endUpdates()
    }
    
    func shouldCollapseLabel(_ label: ExpandableLabel) -> Bool {
        return true
    }

    func willCollapseLabel(_ label: ExpandableLabel) {
        self.tableView.beginUpdates()
    }

    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) {
            if self.tableView.cellForRow(at: indexPath) as? DescriptionBookstopTableViewCell != nil {
                self.isShowMoreDescription = !self.isShowMoreDescription
            }
        }
        self.tableView.endUpdates()
    }
}

extension BookSpaceViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let relativeYOffset = scrollView.contentOffset.y - self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height
        self.height = max(-relativeYOffset, self.bookstopController!.view.frame.height * self.bookstopController!.headerHeightConstraint.multiplier) < self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height ? max(-relativeYOffset, self.bookstopController!.view.frame.height * self.bookstopController!.headerHeightConstraint.multiplier) : self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height
        self.bookstopController?.view.layoutIfNeeded()
        self.bookstopController?.changeFrameProfileView(height: self.height)
    }
}
