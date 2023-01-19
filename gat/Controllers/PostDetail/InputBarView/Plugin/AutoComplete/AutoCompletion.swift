//
//  AutoCompletion.swift
//  gat
//
//  Created by jujien on 5/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

struct AutoCompletion {
    // The String to insert/replace upon autocompletion
    let text: String
    
    // The context of the completion that you may need later when completed
    let context: [String: Any]?
    
    init(text: String, context: [String: Any]?) {
        self.text = text
        self.context = context
    }
}


struct AutoCompletionSession {
    let prefix: String
    let range: NSRange
    var filter: String
    var completion: AutoCompletion?
    var spaceCounter: Int
    
    init(prefix: String, range: NSRange, filter: String) {
        self.prefix = prefix
        self.range = range
        self.filter = filter
        self.spaceCounter = 0
    }
}

extension AutoCompletionSession: Equatable {
    static func == (lhs: AutoCompletionSession, rhs: AutoCompletionSession) -> Bool {
        lhs.prefix == rhs.prefix && lhs.filter == rhs.filter
    }
    
    
}
