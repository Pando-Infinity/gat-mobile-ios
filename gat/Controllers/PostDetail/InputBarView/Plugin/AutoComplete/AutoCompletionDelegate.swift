//
//  AutoCompletionDelegate.swift
//  gat
//
//  Created by jujien on 5/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

/// AutoCompleteDelegate is a protocol that more precisely define AutoCompleteInput logic
protocol AutoCompletionDelegate: class {
    
    /// The autocomplete options for the registered prefix.
    ///
    /// - Parameters:
    ///   - autoCompletionInput: The AutoCompletionInput
    ///   - prefix: The registered prefix
    ///   - text:
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, autocompleteSourceFor prefix: String, text: String)
    
    /// Can be used to determine if the AutoCompleteInput should be inserted into an InputStackView
    ///
    /// - Parameters:
    ///   - autoCompleteInput: The AutoCompleteInput
    ///   - prefix: The registered prefix
    ///   - shouldBecomeVisible: If the AutoCompleteInput should be presented or dismissed
    func autoCompleteImput(_ autoCompleteInput: AutoCompleteInput, prefix: String, shouldBecomeVisible: Bool)
    
    /// Determines if a prefix character should be registered to initialize the auto-complete selection table
    ///
    /// - Parameters:
    ///   - manager: The AutocompleteManager
    ///   - prefix: The prefix `Character` could be registered
    ///   - range: The `NSRange` of the prefix in the UITextView managed by the AutoCompleteInput
    /// - Returns: If the prefix should be registered. Default is TRUE
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldRegister prefix: String, at range: NSRange) -> Bool
    
    /// Determines if a prefix character should be unregistered to de-initialize the auto-complete selection table
    ///
    /// - Parameters:
    ///   - autoCompleteInput: The AutoCompleteInput
    ///   - prefix: The prefix character could be unregistered
    ///   - range: The range of the prefix in the UITextView managed by the AutoCompleteInput
    /// - Returns: If the prefix should be unregistered. Default is TRUE
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldUnregister prefix: String) -> Bool
    
    /// Determines if a prefix character can should be autocompleted
    ///
    /// - Parameters:
    ///   - manager: The AutoCompleteInput
    ///   - prefix: The prefix character that is currently registered
    ///   - text: The text to autocomplete with
    /// - Returns: If the prefix can be autocompleted. Default is TRUE
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldComplete prefix: String, with text: String) -> Bool
    
    /// Determines if interact with url when clicking on a text
    /// - Parameters:
    ///   - autoCompleteInput: The AutoCompleteInput
    ///   - url: url contain attributes text
    ///   - range: The range of interactive text
    /// - Returns: Determines the cursor has moved to the interactive position
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldInteractWith url: URL, prefix: String, context: [String: Any]) -> Bool
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, willDeleteCompletion context: [String: Any])
}

extension AutoCompletionDelegate {
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldRegister prefix: String, at range: NSRange) -> Bool { true }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldUnregister prefix: String) -> Bool { true }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldComplete prefix: String, with text: String) -> Bool { true }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, willDeleteCompletion context: [String: Any]) { }
}
