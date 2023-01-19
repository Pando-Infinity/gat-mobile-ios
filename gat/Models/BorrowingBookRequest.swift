//
//  BorrowingBookRequest.swift
//  gat
//
//  Created by HungTran on 4/8/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//
import Foundation

import Foundation
import RealmSwift
import SwiftyJSON

/** Lưu các request mượn sách được gửi tới người dùng đang login*/
class BorrowingBookRequest: Object {
    @objc dynamic var id: Int = -1 // Mã recordId
    /**Người sử hữu sách*/
    @objc dynamic var ownerId: Int = -1
    @objc dynamic var ownerAddress: String = ""
    @objc dynamic var ownerReadCount: Int = 0
    @objc dynamic var ownerSharingCount: Int = 0
    @objc dynamic var ownerName: String = ""
    @objc dynamic var ownerImageId: String = ""
    
    /**Người mượn sách*/
    @objc dynamic var borrowerId: Int = -1
    @objc dynamic var borrowerAddress: String = ""
    @objc dynamic var borrowerReadCount: Int = 0
    @objc dynamic var borrowerSharingCount: Int = 0
    @objc dynamic var borrowerName: String = ""
    @objc dynamic var borrowerImageId: String = ""
    
    /**Mã tin nhắn*/
    @objc dynamic var messageId: Int = -1
    
    /**Mã cuốn sách thuộc về người dùng đang login*/
    @objc dynamic var instanceId: Int = -1
    
    /**Edition tương ứng của cuốn sách*/
    @objc dynamic var bookEdition: PublicSharingBookEdition?
    
    /**Tên của Edition*/
    
    /**
     + 0: Wait confirm                            Sharing
     + 1: On hold                                   Sharing
     + 2: Contacting                              Sharing
     + 3: Borrowing                               Borrowing
     + 4: Completed                              Sharing
     + 5: Rejected                                 Sharing
     + 6: Canceled                                Sharing
     + 7: Unreturned                              Lost
     */
    @objc dynamic var recordStatus: Int = -1
    
    /**Biến quy định thứ tự xuất hiện request
     wait confirm  0 => 0
     contacting    2 => 1
     borrowing     3 => 2
     on hold       1 => 3
     completed     4 => 4
     unreturned    7 => 5
     canceled      6 => 6
     rejected      5 => 7*/
    @objc dynamic var recordOrder: Int = -1
    
    /**1: sharing request (Những yêu cầu tới mình) 2: borrowing request (những yêu cầu từ mình gửi đi) */
    @objc dynamic var recordType: Int = -1
    
    /*
     Show new page "page_send_request" sau khi user click vào "Mượn sách" hoặc "Đợi mượn".
     + 0: 3 ngày
     + 1: 1 tuần (default)
     + 2: 2 tuần
     + 3: 3 tuần
     + 4: 1 tháng
     */
    @objc dynamic var borrowExpectation: Int = 1
    var borrowExpectationString: String {
        switch borrowExpectation {
        case 0:
            return String(format: self.borrowExpectation > 1 ? Gat.Text.Date.DAYS : Gat.Text.Date.ONE_DAY, 3)
        case 1, 2, 3:
            return String(format: self.borrowExpectation > 1 ? Gat.Text.Date.WEEKS : Gat.Text.Date.ONE_WEEK, self.borrowExpectation)
        case 4:
            return String(format: self.borrowExpectation > 1 ? Gat.Text.Date.MONTHS : Gat.Text.Date.ONE_MONTH, 1)
        default:
            return ""
        }
    }
    
    /**Lý do onHold:
     0: Hiện tại tất cả sách đều đang được mượn. Yêu cầu sẽ tự động
     chuyển sang trạng thái "Đợi đồng ý" sau khi sách được trả.
     1: Hiện người dùng đang mượn đủ số lượng sách tối đa cho phép - 5 quyển. Yêu cầu sẽ tự động chuyển sang trạng thái "Đợi đồng ý" sau khi người dùng trả sách đang mượn
     */
    @objc dynamic var onHoldReasonId: Int = -1
    /**Format: 2017-03-30 13:27:45
     Thời điểm gửi request*/
    @objc dynamic var requestTime: NSDate = NSDate()
    /**Format: 2017-03-30 13:27:45
     Thời điểm được chấp nhận request*/
    @objc dynamic var approveTime: NSDate = NSDate()
    /**Format: 2017-03-30 13:27:45
     Thời điểm mượn sách*/
    @objc dynamic var borrowTime: NSDate = NSDate()
    /**Format: 2017-03-30 13:27:45
     Thời điểm mượn & trả xong*/
    @objc dynamic var completeTime: NSDate = NSDate()
    /**Format: 2017-03-30 13:27:45
     Thời điểm người gửi chủ động huỷ bỏ yêu cầu*/
    @objc dynamic var cancelTime: NSDate = NSDate()
    /**Format: 2017-03-30 13:27:45
     Thời điểm người sử hữu sách từ chối*/
    @objc dynamic var rejectTime: NSDate = NSDate()
    
    /*Cài đặt khoá chính cho bảng BookInstant*/
    override static func primaryKey() -> String? {
        return "id"
    }
    
    /**Lấy ra thứ tự của record dựa theo bảng tham chiếu sau*/
    static func getRecordOrder(_ recordStatus: Int) -> Int {
        /**Biến quy định thứ tự xuất hiện request
         wait confirm  0 => 0
         contacting    2 => 1
         borrowing     3 => 2
         on hold       1 => 3
         completed     4 => 4
         unreturned    7 => 5
         canceled      6 => 6
         rejected      5 => 7*/
        var recordOrderDict: [Int: Int] = [
            -1: -1,
            0: 0,
            2: 1,
            3: 2,
            1: 3,
            4: 4,
            7: 5,
            6: 6,
            5: 7
        ]
        return recordOrderDict[recordStatus]!
    }
    
    /**Một số hàm xử lý liên quan tới BorrowingBookRequest*/
    static func parseFrom(json: JSON, isDetail: Bool = false) -> BorrowingBookRequest? {
        guard let id = json["recordId"].int else {
            return nil
        }
        
//        print("#####", json)
        
        if let request = try! Realm().object(ofType: BorrowingBookRequest.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["instanceId"].exists(), let instanceId = json["instanceId"].int {
                    request.instanceId = instanceId
                }
                if json["messageId"].exists(), let messageId = json["messageId"].int {
                    request.messageId = messageId
                }
                if json["recordStatus"].exists(), let recordStatus = json["recordStatus"].int {
                    request.recordStatus = recordStatus
                    request.recordOrder = BorrowingBookRequest.getRecordOrder(request.recordStatus)
                }
                if json["recordType"].exists(), let recordType = json["recordType"].int {
                    request.recordType = recordType
                }
                if json["onHoldReasonId"].exists(), let onHoldReasonId = json["onHoldReasonId"].int {
                    request.onHoldReasonId = onHoldReasonId
                }
                
                if json["borrowExpectation"].exists(), let borrowExpectation = json["borrowExpectation"].int {
                    request.borrowExpectation = borrowExpectation
                }
                
                var bookEditionJson: JSON!
                if !isDetail {
                    bookEditionJson = [
                        "editionId": json["editionId"],
                        "bookId": json["bookId"],
                        "title": json["editionTitle"]
                    ]
                } else {
                    bookEditionJson = json["editionInfo"]
                }
                
                request.bookEdition = PublicSharingBookEdition.parseFrom(json: bookEditionJson)
                
                if !isDetail {
                    request.borrowerId = json["borrowerId"].int ?? -1
                    request.borrowerName = json["borrowerName"].string ?? ""
                    request.borrowerImageId = json["borrowerImageId"].string ?? ""
                    
                    request.ownerId = json["ownerId"].int ?? -1
                    request.ownerName = json["ownerName"].string ?? ""
                    request.ownerImageId = json["ownerImageId"].string ?? ""
                } else {
                    request.borrowerId = json["borrowerInfo"]["userId"].int ?? -1
                    request.borrowerName = json["borrowerInfo"]["name"].string ?? ""
                    request.borrowerAddress = json["borrowerInfo"]["address"].string ?? ""
                    request.borrowerImageId = json["borrowerInfo"]["imageId"].string ?? ""
                    request.borrowerReadCount = json["borrowerInfo"]["readCount"].int ?? 0
                    request.borrowerSharingCount = json["borrowerInfo"]["sharingCount"].int ?? 0
                    
                    request.ownerId = json["ownerInfo"]["userId"].int ?? -1
                    request.ownerName = json["ownerInfo"]["name"].string ?? ""
                    request.ownerAddress = json["ownerInfo"]["address"].string ?? ""
                    request.ownerImageId = json["ownerInfo"]["imageId"].string ?? ""
                    request.ownerReadCount = json["ownerInfo"]["readCount"].int ?? 0
                    request.ownerSharingCount = json["ownerInfo"]["sharingCount"].int ?? 0
                }
                
                if json["requestTime"].exists(), let requestTime = json["requestTime"].int64 {
                    request.requestTime = NSDate(timeIntervalSince1970: TimeInterval(requestTime/1000))
                }
                
                if json["approveTime"].exists(), let approveTime = json["approveTime"].int64 {
                    request.approveTime = NSDate(timeIntervalSince1970: TimeInterval(approveTime/1000))
                }
                
                if json["borrowTime"].exists(), let borrowTime = json["borrowTime"].int64 {
                    request.borrowTime = NSDate(timeIntervalSince1970: TimeInterval(borrowTime/1000))
                }
                
                if json["completeTime"].exists(), let completeTime = json["completeTime"].int64 {
                    request.completeTime = NSDate(timeIntervalSince1970: TimeInterval(completeTime/1000))
                }
                
                if json["cancelTime"].exists(), let cancelTime = json["cancelTime"].int64 {
                    request.cancelTime = NSDate(timeIntervalSince1970: TimeInterval(cancelTime/1000))
                }
                
                if json["rejectTime"].exists(), let rejectTime = json["rejectTime"].int64 {
                    request.rejectTime = NSDate(timeIntervalSince1970: TimeInterval(rejectTime/1000))
                }

            }
            return request
        } else {
            let request = BorrowingBookRequest()
            request.id = id
            
            var bookEditionJson: JSON!
            if !isDetail {
                bookEditionJson = [
                    "editionId": json["editionId"],
                    "bookId": json["bookId"],
                    "title": json["editionTitle"]
                ]
            } else {
                bookEditionJson = json["editionInfo"]
            }
            
            request.bookEdition = PublicSharingBookEdition.parseFrom(json: bookEditionJson)
            request.onHoldReasonId = json["onHoldReasonId"].int ?? -1
            request.instanceId = json["instanceId"].int ?? -1
            request.messageId = json["messageId"].int ?? -1
            request.recordStatus = json["recordStatus"].int ?? -1
            request.recordOrder = BorrowingBookRequest.getRecordOrder(request.recordStatus)
            request.recordType = json["recordType"].int ?? -1
            
            request.borrowExpectation = json["borrowExpectation"].int ?? 1
            
            if !isDetail {
                request.borrowerId = json["borrowerId"].int ?? -1
                request.borrowerName = json["borrowerName"].string ?? ""
                request.borrowerImageId = json["borrowerImageId"].string ?? ""
                
                request.ownerId = json["ownerId"].int ?? -1
                request.ownerName = json["ownerName"].string ?? ""
                request.ownerImageId = json["ownerImageId"].string ?? ""
            } else {
                request.borrowerId = json["borrowerInfo"]["userId"].int ?? -1
                request.borrowerName = json["borrowerInfo"]["name"].string ?? ""
                request.borrowerAddress = json["borrowerInfo"]["address"].string ?? ""
                request.borrowerImageId = json["borrowerInfo"]["imageId"].string ?? ""
                request.borrowerReadCount = json["borrowerInfo"]["readCount"].int ?? 0
                request.borrowerSharingCount = json["borrowerInfo"]["sharingCount"].int ?? 0
                
                request.ownerId = json["ownerInfo"]["userId"].int ?? -1
                request.ownerName = json["ownerInfo"]["name"].string ?? ""
                request.ownerAddress = json["ownerInfo"]["address"].string ?? ""
                request.ownerImageId = json["ownerInfo"]["imageId"].string ?? ""
                request.ownerReadCount = json["ownerInfo"]["readCount"].int ?? 0
                request.ownerSharingCount = json["ownerInfo"]["sharingCount"].int ?? 0
            }
            
            if let requestTime = json["requestTime"].int64 {
                request.requestTime = NSDate(timeIntervalSince1970: TimeInterval(requestTime/1000))
            }
            
            if let approveTime = json["approveTime"].int64 {
                request.approveTime = NSDate(timeIntervalSince1970: TimeInterval(approveTime/1000))
            }
            
            if let borrowTime = json["borrowTime"].int64 {
                request.borrowTime = NSDate(timeIntervalSince1970: TimeInterval(borrowTime/1000))
            }
            
            if let completeTime = json["completeTime"].int64 {
                request.completeTime = NSDate(timeIntervalSince1970: TimeInterval(completeTime/1000))
            }
            
            if let cancelTime = json["cancelTime"].int64 {
                request.cancelTime = NSDate(timeIntervalSince1970: TimeInterval(cancelTime/1000))
            }
            
            if let rejectTime = json["rejectTime"].int64 {
                request.rejectTime = NSDate(timeIntervalSince1970: TimeInterval(rejectTime/1000))
            }
            
            return request
        }
    }
}
