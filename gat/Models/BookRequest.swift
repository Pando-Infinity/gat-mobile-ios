//
//  BookRequest.swift
//  gat
//
//  Created by Vũ Kiên on 27/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

enum RecordStatus: Int, CaseIterable {
    case waitConfirm = 0
    case onHold = 1
    case contacting = 2
    case borrowing = 3
    case completed = 4
    case rejected = 5
    case cancelled = 6
    case unreturned = 7
    case other = -1
}

enum RequestType: Int {
    case sharing = 1
    case borrowing = 2
}

enum ExpectedTime: Int {
    case threeDays = 0
    case aWeek = 1
    case twoWeeks = 2
    case threeWeeks = 3
    case aMonth = 4
    
    static let all: [ExpectedTime] = [.threeDays, .aWeek, .twoWeeks, .threeWeeks, .aMonth]
    
    var toString: String {
        switch self {
        case .threeDays:
            return String(format: Gat.Text.Date.DAYS.localized(), 3)
        case .aWeek, .twoWeeks, .threeWeeks:
            if (self.rawValue == 1) {
                return String(format: Gat.Text.Date.ONE_WEEK.localized(), self.rawValue)
            }
            return String(format: Gat.Text.Date.WEEKS.localized(), self.rawValue)
        case .aMonth:
            return String(format: Gat.Text.Date.ONE_MONTH.localized(), 1)
        }
    }
    
}

enum BorrowType: Int {
    case userWithUser = 1
    case userWithBookstop = 5
}

class BookRequest {
    var recordId: Int = -1
    var book: BookInfo?
    var owner: Profile?
    var borrower: Profile?
    var recordType: RequestType?
    var recordStatus: RecordStatus?
    var recordOrder: RecordStatus?
    var borrowType: BorrowType = .userWithUser
    var borrowExpectation: ExpectedTime = .aWeek
    
    /**Lý do onHold:
     0: Hiện tại tất cả sách đều đang được mượn. Yêu cầu sẽ tự động
     chuyển sang trạng thái "Đợi đồng ý" sau khi sách được trả.
     1: Hiện người dùng đang mượn đủ số lượng sách tối đa cho phép - 5 quyển. Yêu cầu sẽ tự động chuyển sang trạng thái "Đợi đồng ý" sau khi người dùng trả sách đang mượn
     */
    var onHoldReasonId: Int?
    
    var requestTime: Date?
    var approveTime: Date?
    var borrowTime: Date?
    var completeTime: Date?
    var cancelTime: Date?
    var rejectTime: Date?
    var lostTime: Date?
    
    init() {
        self.book = BookInfo()
        self.owner = Profile()
        self.borrower = Profile()
    }
}

extension BookRequest: ObjectConvertable {
    typealias Object = BookRequestObject
    
    func asObject() -> BookRequestObject {
        let object = BookRequestObject()
        object.recordId = self.recordId
        object.book = self.book?.asObject()
        object.owner = self.owner?.asObject()
        object.borrower = self.borrower?.asObject()
        object.recordType = self.recordType?.rawValue ?? -1
        object.recordStatus = self.recordStatus?.rawValue ?? -1
        object.recordOrder = self.recordOrder?.rawValue ?? -1
        object.borrowType = self.borrowType.rawValue
        object.borrowExpectation = self.borrowExpectation.rawValue
        object.onHoldReasonId.value = self.onHoldReasonId
        object.requestTime = self.requestTime
        object.approveTime = self.approveTime
        object.borrowTime = self.borrowTime
        object.completeTime = self.completeTime
        object.cancelTime = self.cancelTime
        object.rejectTime = self.rejectTime
        object.lostTime = self.lostTime
        return object
    }
    
    
}

class BookRequestObject: Object {
    @objc dynamic var recordId: Int = 0
    @objc dynamic var book: BookInfoObject?
    @objc dynamic var owner: ProfileObject?
    @objc dynamic var borrower: ProfileObject?
    @objc dynamic var recordType: Int = -1
    @objc dynamic var borrowType: Int = 1
    @objc dynamic var recordStatus: Int = -1
    @objc dynamic var recordOrder: Int = -1
    @objc dynamic var borrowExpectation: Int = 1
    let onHoldReasonId: RealmOptional<Int> = RealmOptional()
    @objc dynamic var requestTime: Date?
    @objc dynamic var approveTime: Date?
    @objc dynamic var borrowTime: Date?
    @objc dynamic var completeTime: Date?
    @objc dynamic var cancelTime: Date?
    @objc dynamic var rejectTime: Date?
    @objc dynamic var lostTime: Date?
    
    override static func primaryKey() -> String {
        return "recordId"
    }
    
}

extension BookRequestObject: DomainConvertable {
    typealias Domain = BookRequest
    
    func asDomain() -> BookRequest {
        let domain = BookRequest()
        domain.recordId = self.recordId
        domain.book = self.book?.asDomain()
        domain.owner = self.owner?.asDomain()
        domain.borrower = self.borrower?.asDomain()
        domain.recordType = RequestType(rawValue: self.recordType)
        domain.recordStatus = RecordStatus(rawValue: self.recordStatus)
        domain.recordOrder = RecordStatus(rawValue: self.recordOrder)
        domain.borrowType = BorrowType(rawValue: self.borrowType) ?? .userWithUser
        domain.borrowExpectation = ExpectedTime(rawValue: self.borrowExpectation) ?? .aWeek
        domain.onHoldReasonId = self.onHoldReasonId.value
        domain.requestTime = self.requestTime
        domain.approveTime = self.approveTime
        domain.borrowTime = self.borrowTime
        domain.completeTime = self.completeTime
        domain.cancelTime = self.cancelTime
        domain.rejectTime = self.rejectTime
        domain.lostTime = self.lostTime
        return domain
    }
    
}

extension BookRequestObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.recordId
    }
    
    
}
