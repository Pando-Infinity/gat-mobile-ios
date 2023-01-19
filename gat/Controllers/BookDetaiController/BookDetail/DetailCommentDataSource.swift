//
//  DetailCommentDataSource.swift
//  gat
//
//  Created by Vũ Kiên on 13/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class DetailCommentDataSource {
    weak var viewcontroller: BookDetailContainerController?
    var datasources: RxTableViewSectionedReloadDataSource<SectionModel<BookDetailContainerController.Section, Any>>!
    var items: BehaviorRelay<[SectionModel<BookDetailContainerController.Section, Any>]>
    fileprivate var disposeBag: DisposeBag
    var showMoreReview: [Bool] = []
    var showMoreDescription = true
    
    init(viewcontroller: BookDetailContainerController, items: BehaviorRelay<[SectionModel<BookDetailContainerController.Section, Any>]>, disposeBag: DisposeBag) {
        self.viewcontroller = viewcontroller
        self.items = items
        self.disposeBag = disposeBag
        self.datasources = RxTableViewSectionedReloadDataSource<SectionModel<BookDetailContainerController.Section, Any>>.init(configureCell: { [weak self] (datasource, tableView, indexPath, element) -> UITableViewCell in
            switch datasource[indexPath.section].identity {
            case .description:
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_DETAIL_BOOK, for: indexPath) as! DetailBookTableViewCell
                cell.dataSource = self
                cell.setupUI(description: element as! String)
                return cell
            case .reading:
                let cell = tableView.dequeueReusableCell(withIdentifier: HistoryReadingBookTableViewCell.identifier, for: indexPath) as! HistoryReadingBookTableViewCell
                        
                if let reading = element as? ReadingBook {
                    cell.reading.accept(reading)
                } else if let readingNum = element as? Int {
                    cell.numberReadingBook.accept(readingNum)
                        cell.reading.accept(nil)
                }
                return cell
            case .myReview:
                let cell = tableView.dequeueReusableCell(withIdentifier: MyReviewTableViewCell.identifier, for: indexPath) as! MyReviewTableViewCell
                cell.post.accept(element as? Post)
                cell.datasource = self
                if let value = try? self?.viewcontroller?.book.value(), let book = value {
                    cell.book.onNext(book)
                }
                return cell
            case .reviews:
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_COMMENT, for: indexPath) as! CommentTableViewCell
                cell.datasource = self
                cell.post.accept(element as? Post)
                return cell
            }
        })
        self.setup()
    }
    
    func setup() {
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.items
            .asObservable()
            .bind(
                to: self.viewcontroller!.tableView.rx.items(dataSource: self.datasources)
            )
            .disposed(by: self.disposeBag)
    }
}
