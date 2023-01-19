//
//  WalletService.swift
//  gat
//
//  Created by jujien on 08/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import Foundation

class WalletService {
    static let shared = WalletService()
    
    fileprivate var balances: [NetworkCurrency: Double]
    fileprivate var balanceInApp = 100.0
    fileprivate var inAppTransactionHistories: [Transaction] = Transaction.data
    
    fileprivate init() {
        self.balances = [
            .gat: 1000,
            .sol: 1000
        ]
    }
    
    func getBalanceInApp() -> Double {
        return self.balanceInApp
    }
    
    func balance(network: NetworkCurrency) -> Double {
        return self.balances[network] ?? .zero
    }
    
    func totalPrice(network: NetworkCurrency, locale: Locale = .current) -> Double {
        return self.balance(network: network) * 10
    }
    
    func transactionHistoriesInApp(types: [Transaction.TransactionType], status: [Transaction.TransactionStatus], order: Transaction.Order) -> [Transaction] {
        let items = self.inAppTransactionHistories
        let results = items.filter { transaction in
            return status.contains(where: { $0 == transaction.status })
            && types.contains(where: { $0 == transaction.type })
        }
            .filter { transaction in
                switch order {
                case .today: return Calendar.current.isDateInToday(transaction.date)
                case .last7Days: return transaction.date > Date().addingTimeInterval(-604800)
                case .last30Days: return transaction.date > Date().addingTimeInterval(-2_592_000)
                case .last90Days: return transaction.date > Date().addingTimeInterval(-7_776_000)
                }
            }
            .sorted(by: { $0.date > $1.date})
        return results
    }
    
    func donate(user: Profile, amount: Double) throws {
        if self.balanceInApp < amount {
            throw NSError(domain: "balance_enough", code: 1)
        } else {
            self.balanceInApp -= amount
            self.inAppTransactionHistories.insert(.init(id: UUID().uuidString, type: .giveDonation, date: Date(), amount: amount, status: .processing, operation: .toUser(user)), at: 0)
        }
        
    }
    
    func cancel(transaction: Transaction) {
        self.balanceInApp += transaction.amount
        if let index = self.inAppTransactionHistories.firstIndex(where: { $0.id == transaction.id }) {
            var t = self.inAppTransactionHistories[index]
            t.status = .canceled
            self.inAppTransactionHistories[index] = t
        }
    }
    
    
}
