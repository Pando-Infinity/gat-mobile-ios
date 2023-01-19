//
//  DecoratorAutoComplete.swift
//  gat
//
//  Created by jujien on 5/12/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation


protocol PrefixAutoComplete {
    var prefix: String { get }
    
    var attributedTextAttributes: [NSAttributedString.Key:Any]? { get set }

    var tags: Set<TagComment> { get set }
    
    func removeAllTags()
}


class DecoratorAutoComplete: AutoCompletionDelegate {
    
    var autoCompletes: [AutoCompletionDelegate & PrefixAutoComplete]
    
    var tags: Set<TagComment> {
        self.autoCompletes.reduce(Set<TagComment>(), { $0.union($1.tags) })
    }
            
    init(autoCompletes: [AutoCompletionDelegate & PrefixAutoComplete]) {
        self.autoCompletes = autoCompletes
    }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, autocompleteSourceFor prefix: String, text: String) {
        self.autoCompletes.first(where: { $0.prefix == prefix })?.autoCompleteInput(autoCompleteInput, autocompleteSourceFor: prefix, text: text)
    }
    
    func autoCompleteImput(_ autoCompleteInput: AutoCompleteInput, prefix: String, shouldBecomeVisible: Bool) {
        if shouldBecomeVisible {
            self.autoCompletes.first(where: { $0.prefix == prefix })?.autoCompleteImput(autoCompleteInput, prefix: prefix, shouldBecomeVisible: shouldBecomeVisible)
        } else {
            self.autoCompletes.forEach { $0.autoCompleteImput(autoCompleteInput, prefix: prefix, shouldBecomeVisible: shouldBecomeVisible) }
        }
        
    }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldInteractWith url: URL, prefix: String, context: [String: Any]) -> Bool {
        return self.autoCompletes.first(where: { $0.prefix == prefix })?.autoCompleteInput(autoCompleteInput, shouldInteractWith: url, prefix: prefix, context: context) ?? true 
    }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, willDeleteCompletion context: [String : Any]) {
        guard let prefix = context["prefix"] as? String else { return }
        self.autoCompletes.first(where: { $0.prefix == prefix })?.autoCompleteInput(autoCompleteInput, willDeleteCompletion: context)
    }
    
    func removeAllTags() {
        self.autoCompletes.forEach { $0.removeAllTags() }
    }
}

