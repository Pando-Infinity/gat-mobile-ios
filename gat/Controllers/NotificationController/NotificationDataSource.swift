//
//  NotificationDataSource.swift
//  gat
//
//  Created by Vũ Kiên on 30/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class NotificationDataSource {
    var datasources: RxTableViewSectionedReloadDataSource<SectionModel<String, UserNotification>>!
    fileprivate var disposeBag: DisposeBag
    
    init() {
        self.datasources = RxTableViewSectionedReloadDataSource<SectionModel<String, UserNotification>>.init(configureCell: { (datasource, tableView, indexPath, notification) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_NOTIFICATION, for: indexPath) as!NotificationTableViewCell
            cell.setup(notification: notification)
            return cell
        })
        self.disposeBag = DisposeBag()
    }
}
