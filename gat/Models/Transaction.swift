//
//  Transactiontype.swift
//  gat
//
//  Created by jujien on 05/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import Foundation

struct Transaction {
    
    var id: String
    var type: TransactionType
    var date: Date
    var amount: Double
    var status: TransactionStatus
    var operation: Operation
    
    init(id: String, type: TransactionType, date: Date, amount: Double, status: TransactionStatus, operation: Transaction.Operation) {
        self.id = id
        self.type = type
        self.date = date
        self.amount = amount
        self.status = status
        self.operation = operation
    }

    
    enum TransactionType: CaseIterable {
        case giveDonation
        case receiveDonation
        case transferToGAT
        case borrowBookFee
        case refundBookBorrowFee
        case refundDepositFee
        case extensionFee
        case refundExtensionFee
        case overdueFee
        case send
        case receive
        case transferToApp
    }
    
    enum TransactionStatus: CaseIterable {
        case processing
        case success
        case failed
        case canceled
    }
    
    enum Operation {
        case app
        case fromUser(Profile)
        case toUser(Profile)
        case fromAddress(String)
        case toAddress(String)
    }
    
    enum Order: CaseIterable {
        case today
        case last7Days
        case last30Days
        case last90Days
    }
}

extension Transaction {
    static var data: [Transaction] {
        return [
            .init(id: UUID().uuidString, type: .giveDonation, date: Date(timeIntervalSince1970: 1670125327), amount: 1, status: .processing, operation: .toUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .transferToGAT, date: Date(timeIntervalSince1970: 1669866127), amount: 200, status: .processing, operation: .app),
            .init(id: UUID().uuidString, type: .giveDonation, date: Date(timeIntervalSince1970: 1669891327), amount: 20, status: .success, operation: .toUser(Profile(id: 0, username: "minh.ngoc", name: "ngox.123", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .transferToGAT, date: Date(timeIntervalSince1970: 1669862527), amount: 200, status: .success, operation: .app),
            .init(id: UUID().uuidString, type: .giveDonation, date: Date(timeIntervalSince1970: 1669776127), amount: 50, status: .failed, operation: .toUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .giveDonation, date: Date(timeIntervalSince1970: 1669772527), amount: 10, status: .canceled, operation: .toUser(Profile(id: 0, username: "minh.ngoc", name: "ngox.123", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .transferToGAT, date: Date(timeIntervalSince1970: 1669686127), amount: 300, status: .canceled, operation: .app),
            .init(id: UUID().uuidString, type: .borrowBookFee, date: Date(timeIntervalSince1970: 1669675327), amount: 30, status: .success, operation: .toUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .receiveDonation, date: Date(timeIntervalSince1970: 1669614127), amount: 25, status: .processing, operation: .fromUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .refundBookBorrowFee, date: Date(timeIntervalSince1970: 1669527727), amount: 30, status: .success, operation: .fromUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .extensionFee, date: Date(timeIntervalSince1970: 1669268527), amount: 20, status: .success, operation: .fromUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .refundDepositFee, date: Date(timeIntervalSince1970: 1669011007), amount: 30, status: .success, operation: .fromUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .giveDonation, date: Date(timeIntervalSince1970: 1670125327), amount: 1, status: .success, operation: .fromUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1))),
            .init(id: UUID().uuidString, type: .overdueFee, date: Date(timeIntervalSince1970: 1668777007), amount: 1, status: .success, operation: .toUser(Profile(id: 0, username: "quoc.anh", name: "Nguyen Quoc Anh", address: "", imageId: "", email: "", about: "", latitude: 0, longitude: 0, userTypeFlag: 1)))
        ]
    }
    
    static var data1: [Transaction] {
        return [
            .init(id: UUID().uuidString, type: .send, date: Date(timeIntervalSince1970: 1670361190), amount: 10, status: .processing, operation: .toAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .receive, date: Date(timeIntervalSince1970: 1670274790), amount: 20, status: .processing, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .transferToApp, date: Date(timeIntervalSince1970: 1670263990), amount: 100, status: .processing, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .send, date: Date(timeIntervalSince1970: 1670209990), amount: 40, status: .success, operation: .toAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .receive, date: Date(timeIntervalSince1970: 1669345990), amount: 50, status: .failed, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .send, date: Date(timeIntervalSince1970: 1668049990), amount: 300, status: .canceled, operation: .toAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .transferToApp, date: Date(timeIntervalSince1970: 1667272390), amount: 300, status: .success, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .receive, date: Date(timeIntervalSince1970: 1667049190), amount: 30, status: .success, operation: .toAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .send, date: Date(timeIntervalSince1970: 1666876390), amount: 25, status: .failed, operation: .toAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .receive, date: Date(timeIntervalSince1970: 1666789990), amount: 30, status: .canceled, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .receive, date: Date(timeIntervalSince1970: 1666771990), amount: 20, status: .success, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .send, date: Date(timeIntervalSince1970: 1666675590), amount: 10, status: .failed, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .send, date: Date(timeIntervalSince1970: 1666599190), amount: 1, status: .success, operation: .toAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64")),
            .init(id: UUID().uuidString, type: .transferToApp, date: Date(timeIntervalSince1970: 1666080790), amount: 1, status: .canceled, operation: .fromAddress("0xbc1q0jplvq4upmr60g53py6nqlhq4k0s4ahswgwg64"))
        ]
    }
}
