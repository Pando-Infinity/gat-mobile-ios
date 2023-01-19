//
//  AutoCompletePlugin.swift
//  gat
//
//  Created by jujien on 5/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import InputBarAccessoryView
import UIKit

class AutoCompleteInput: NSObject {
    
    /// Adds an additional space after the autocompleted text when true.
    /// Default value is `TRUE`
    var appendSpaceOnCompletion = true
    
    /// Keeps the prefix typed when text is autocompleted.
    /// Default value is `FALSE`
    var keepPrefixOnCompletion = false
    
    /// Allows a single space character to be entered mid autocompletion.
    ///
    /// For example, your autocomplete is "Nathan Tannar", the .whitespace deliminater
    /// set would terminate the session after "Nathan". By setting `maxSpaceCountDuringCompletion`
    /// the session termination will disregard that number of spaces
    ///
    /// Default value is `0`
    var maxSpaceCountDuringCompletion: Int = 0

    /// When enabled, autocomplete completions that contain whitespace will be deleted in parts.
    /// This meands backspacing on "@Nathan Tannar" will result in " Tannar" being removed first
    /// with a second backspace action required to delete "@Nathan"
    ///
    /// Default value is `TRUE`
    var deleteCompletionByParts = true
    
    /// The default text attributes
    open var defaultTextAttributes: [NSAttributedString.Key: Any] =
        [.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.black]
    
    /// The NSAttributedString.Key.paragraphStyle value applied to attributed strings
    public let paragraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacingBefore = 2
        style.lineHeightMultiple = 1
        return style
    }()
    
    weak var delegate: AutoCompletionDelegate?
    
    // MARK: - Properties [Private]
    fileprivate(set) public weak var textView: UITextView?
    
    // MARK: - Properties [Private]
    
    /// The prefices that the manager will recognize
    public fileprivate(set) var autocompletePrefixes = Set<String>()
    
    /// The delimiters that the manager will terminate a session with
    /// The default value is: [.whitespaces, .newlines]
    public fileprivate(set) var autocompleteDelimiterSets: Set<CharacterSet> = [.whitespaces, .newlines]
    
    /// The text attributes applied to highlighted substrings for each prefix
    public fileprivate(set) var autocompleteTextAttributes = [String: [NSAttributedString.Key: Any]]()
    
    /// A reference to `defaultTextAttributes` that adds the NSAttributedAutocompleteKey
    private var typingTextAttributes: [NSAttributedString.Key: Any] {
        var attributes = self.defaultTextAttributes
        attributes[.autocompleted] = false
        attributes[.autocompletedContext] = nil
        attributes[.paragraphStyle] = self.paragraphStyle
        return attributes
    }
    
    /// An ongoing session reference that holds the prefix, range and text to complete with
    fileprivate var currentSession: AutoCompletionSession?
    
    init(textView: UITextView) {
        self.textView = textView
        super.init()
        self.textView?.delegate = self
    }
}

extension AutoCompleteInput {
    /// Registers a prefix and its the attributes to apply to its autocompleted strings
    ///
    /// - Parameters:
    ///   - prefix: The prefix such as: @, # or !
    ///   - attributedTextAttributes: The attributes to apply to the NSAttributedString
    func register(prefix: String, with attributedTextAttributes: [NSAttributedString.Key:Any]? = nil) {
        self.autocompletePrefixes.insert(prefix)
        self.autocompleteTextAttributes[prefix] = attributedTextAttributes
        self.autocompleteTextAttributes[prefix]?[.paragraphStyle] = self.paragraphStyle
    }
    
    // Unregisters a prefix and removes its associated cached attributes
    ///
    /// - Parameter prefix: The prefix such as: @, # or !
    func unregister(prefix: String) {
        self.autocompletePrefixes.remove(prefix)
        self.autocompleteTextAttributes[prefix] = nil
    }
    
    /// Registers a CharacterSet as a delimiter
    ///
    /// - Parameter delimiterSet: The `CharacterSet` to recognize as a delimiter
    func register(delimiterSet set: CharacterSet) {
        self.autocompleteDelimiterSets.insert(set)
    }
    
    /// Unregisters a CharacterSet
    ///
    /// - Parameter delimiterSet: The `CharacterSet` to recognize as a delimiter
    func unregister(delimiterSet set: CharacterSet) {
        self.autocompleteDelimiterSets.remove(set)
    }
    
    func set(completion: AutoCompletion) {
        guard var session = self.currentSession else { return }
        session.completion = completion
        self.currentSession = session
        self.autocomplete(with: session)
    }
    
    /// Replaces the current prefix and filter text with the supplied text
    ///
    /// - Parameters:
    ///   - text: The replacement text
    func autocomplete(with session: AutoCompletionSession) {
        guard let textView = self.textView, self.delegate?.autoCompleteInput(self, shouldComplete: session.prefix, with: session.filter) != false else { return }
        // Create a range that overlaps the prefix
        let prefixLength = session.prefix.utf16.count
        let insertionRange = NSRange(
            location: session.range.location + (self.keepPrefixOnCompletion ? prefixLength : 0),
            length: session.filter.utf16.count + (!self.keepPrefixOnCompletion ? prefixLength : 0)
        )
        
        // Transform range
        guard let range = Range(insertionRange, in: textView.text) else { return }
        let nsrange = NSRange(range, in: textView.text)
        // Replace the attributedText with a modified version
        let autocomplete = session.completion?.text ?? ""
        self.insertAutocomplete(autocomplete, at: session, for: nsrange)
        
        // Move Cursor to the end of the inserted text
        let selectedLocation = insertionRange.location + autocomplete.utf16.count + (self.appendSpaceOnCompletion ? 1 : 0)
        textView.selectedRange = NSRange(
            location: selectedLocation,
            length: 0
        )
        
        // End the session
        self.unregisterCurrentSession()
    }
    
    func attributedText(matching text: String, fontSize: CGFloat = 15, foregroundColor: UIColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1), keepPrefix: Bool = true) -> NSMutableAttributedString {
        guard let session = self.currentSession else { return .init(string: text) }
        let matchingRange = (text as NSString).range(of: session.filter, options: .caseInsensitive)
        let attributes = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: fontSize, weight: .regular), .foregroundColor: foregroundColor])
        attributes.addAttributes([.font: UIFont.boldSystemFont(ofSize: fontSize)], range: matchingRange)
        guard keepPrefix else { return attributes }
        attributes.insert(.init(string: session.prefix, attributes: [.font: UIFont.systemFont(ofSize: fontSize), .foregroundColor: foregroundColor]), at: 0)
        return attributes
    }
}

extension AutoCompleteInput {
    
    /// Resets the `InputTextView`'s typingAttributes to `defaultTextAttributes`
    fileprivate func preserveTypingAttributes() {
        self.textView?.typingAttributes = self.typingTextAttributes
    }
    
    fileprivate func unregisterCurrentSession() {
        guard let session = self.currentSession, self.delegate?.autoCompleteInput(self, shouldUnregister: session.prefix) != false else { return }
        
        self.currentSession = nil
        self.delegate?.autoCompleteImput(self, prefix: session.prefix, shouldBecomeVisible: false)
    }
    
    fileprivate func updateCurrentSession(to filterText: String) {
        guard var session = self.currentSession else { return }
        session.filter = filterText
        self.currentSession = session
        self.delegate?.autoCompleteImput(self, prefix: session.prefix, shouldBecomeVisible: true)
        self.retrieveText()
    }
    
    fileprivate func registerCurrentSession(to session: AutoCompletionSession) {
        guard self.delegate?.autoCompleteInput(self, shouldRegister: session.prefix, at: session.range) != false else { return }
        self.currentSession = session
        self.delegate?.autoCompleteImput(self, prefix: session.prefix, shouldBecomeVisible: true)
        self.retrieveText()
    }
    
    fileprivate func retrieveText() {
        guard let session = self.currentSession else { return }
        self.delegate?.autoCompleteInput(self, autocompleteSourceFor: session.prefix, text: session.filter)
    }
    
    /// Inserts an autocomplete for a given selection
    ///
    /// - Parameters:
    ///   - autocomplete: The 'String' to autocomplete to
    ///   - sesstion: The 'AutocompleteSession'
    ///   - range: The 'NSRange' to insert over
    fileprivate func insertAutocomplete(_ autocomplete: String, at session: AutoCompletionSession, for range: NSRange) {
        guard let textView = self.textView else { return }
        
        // Apply the autocomplete attributes
        var attrs = self.autocompleteTextAttributes[session.prefix] ?? self.defaultTextAttributes
        attrs[.autocompleted] = true
        attrs[.autocompletedContext] = session.completion?.context
        let newString = (self.keepPrefixOnCompletion ? session.prefix : "") + autocomplete
        let newAttributedString = NSAttributedString(string: newString, attributes: attrs)
        
        // Modify the NSRange to include the prefix length
        let rangeModifier = self.keepPrefixOnCompletion ? session.prefix.count : 0
        let highlightedRange = NSRange(location: range.location - rangeModifier, length: range.length + rangeModifier)
        
        // Replace the attributedText with a modified version including the autocompete
        let newAttributedText = textView.attributedText.replacingCharacters(in: highlightedRange, with: newAttributedString)

        if self.appendSpaceOnCompletion {
            newAttributedText.append(NSAttributedString(string: " ", attributes: typingTextAttributes))
        }
        
        // Set to a blank attributed string to prevent keyboard autocorrect from cloberring the insert
        textView.attributedText = NSAttributedString()

        textView.attributedText = newAttributedText
    }
}

extension AutoCompleteInput: InputPlugin {
    func reloadData() {
        let delimiterSet = self.autocompleteDelimiterSets.reduce(CharacterSet(), { $0.union($1) })
        if let result = self.textView?.find(prefixes: self.autocompletePrefixes, with: delimiterSet) {
            let wordWithoutPrefix = (result.word as NSString).substring(from: result.prefix.utf16.count)
            let session = AutoCompletionSession(prefix: result.prefix, range: result.range, filter: wordWithoutPrefix)
            guard let currentSession = self.currentSession, session.prefix != currentSession.prefix else {
                self.registerCurrentSession(to: session)
                return
            }
            self.updateCurrentSession(to: wordWithoutPrefix)
        } else {
            if let session = self.currentSession, session.spaceCounter <= self.maxSpaceCountDuringCompletion {
                if let result = self.textView?.find(prefixes: [session.prefix], with: delimiterSet) {
                    let wordWithoutPrefix = (result.word as NSString).substring(from: result.prefix.utf16.count)
                    self.updateCurrentSession(to: wordWithoutPrefix)
                } else {
                    self.unregisterCurrentSession()
                }
            } else {
                self.unregisterCurrentSession()
            }
        }
    }
    
    func invalidate() {
        self.unregisterCurrentSession()
    }
    
    func handleInput(of object: AnyObject) -> Bool {
        guard let newText = object as? String, let textView = self.textView else { return false }
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        let newAttributedString = NSAttributedString(string: newText, attributes: self.typingTextAttributes)
        attributedString.append(newAttributedString)
        textView.attributedText = attributedString
        self.reloadData()
        return false
    }
}

extension AutoCompleteInput: InputTextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.reloadData()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.preserveTypingAttributes()
        
        let totalRange = NSRange(location: 0, length: textView.attributedText.length)
        let selectedRange = textView.selectedRange
        
        // range.length > 0: Backspace/removing text
        // range.lowerBound < textView.selectedRange.lowerBound: Ignore trying to delete
        //      the substring if the user is already doing so
        // range == selectedRange: User selected a chunk to delete
        if range.length > 0, range.location < selectedRange.location {
            // Backspace/removing text
            let attributes = textView.attributedText.attributes(at: range.location, longestEffectiveRange: nil, in: range)
            let isAutocompleted = attributes[.autocompleted] as? Bool ?? false
            
            if isAutocompleted {
                textView.attributedText.enumerateAttribute(.autocompleted, in: totalRange, options: .reverse) { _, subrange, stop in
                    
                    let intersection = NSIntersectionRange(range, subrange)
                    guard intersection.length > 0 else { return }
                    defer { stop.pointee = true }
                    if let context = textView.attributedText.attribute(.autocompletedContext, at: subrange.location, effectiveRange: nil) as? [String: Any] {
                        self.delegate?.autoCompleteInput(self, willDeleteCompletion: context)
                    }
                    let nothing = NSAttributedString(string: "", attributes: self.typingTextAttributes)

                    let textToReplace = textView.attributedText.attributedSubstring(from: subrange).string
                    guard self.deleteCompletionByParts, let delimiterRange = textToReplace.rangeOfCharacter(from: .whitespacesAndNewlines, options: .backwards, range: Range(subrange, in: textToReplace)) else {
                        // Replace entire autocomplete
                        textView.attributedText = textView.attributedText.replacingCharacters(in: subrange, with: nothing)
                        textView.selectedRange = NSRange(location: subrange.location, length: 0)
                        return
                    }
                    // Delete up to delimiter
                    let delimiterLocation = delimiterRange.lowerBound.utf16Offset(in: textToReplace)
                    let length = subrange.length - delimiterLocation
                    let rangeFromDelimiter = NSRange(location: delimiterLocation + subrange.location, length: length)
                    textView.attributedText = textView.attributedText.replacingCharacters(in: rangeFromDelimiter, with: nothing)
                    textView.selectedRange = NSRange(location: subrange.location + delimiterLocation, length: 0)
                }
                self.unregisterCurrentSession()
                return false
            }
        } else if range.length >= 0, range.location < totalRange.length {
            // Inserting text before a tag when the tag is at the start of the string
            guard range.location != 0 else { return true }

            // Inserting text in the middle of an autocompleted string
            let attributes = textView.attributedText.attributes(at: range.location-1, longestEffectiveRange: nil, in: NSMakeRange(range.location-1, range.length))

            let isAutocompleted = attributes[.autocompleted] as? Bool ?? false
            if isAutocompleted {
                textView.attributedText.enumerateAttribute(.autocompleted, in: totalRange, options: .reverse) { _, subrange, stop in
                    
                    let compareRange = range.length == 0 ? NSRange(location: range.location, length: 1) : range
                    let intersection = NSIntersectionRange(compareRange, subrange)
                    guard intersection.length > 0 else { return }
                    
                    let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
                    mutable.setAttributes(self.typingTextAttributes, range: subrange)
                    let replacementText = NSAttributedString(string: text, attributes: self.typingTextAttributes)
                    textView.attributedText = mutable.replacingCharacters(in: range, with: replacementText)
                    textView.selectedRange = NSRange(location: range.location + text.count, length: 0)
                    stop.pointee = true
                }
                self.unregisterCurrentSession()
                return false
            }
        }
        return true
    }
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, context: [String : Any]) -> Bool {
        guard let prefix = context["prefix"] as? String else { return true }
        return self.delegate?.autoCompleteInput(self, shouldInteractWith: url, prefix: prefix, context: context) ?? true
    }
}

extension UITextView {

    typealias Match = (prefix: String, word: String, range: NSRange)
    
    func find(prefixes: Set<String>, with delimiterSet: CharacterSet) -> Match? {
        guard !prefixes.isEmpty else { return nil }

        let matches = prefixes.compactMap { self.find(prefix: $0, with: delimiterSet) }
        let sorted = matches.sorted { a, b in
            return a.range.lowerBound > b.range.lowerBound
        }
        return sorted.first
    }
    
    func find(prefix: String, with delimiterSet: CharacterSet) -> Match? {
        guard let caretRange = self.caretRange, let cursorRange = Range(caretRange, in: self.text), !prefix.isEmpty else { return nil }
        
        let leadingText = self.text[..<cursorRange.upperBound]
        var prefixStartIndex: String.Index!
        for (i, char) in prefix.enumerated() {
            guard let index = leadingText.lastIndex(of: char) else { return nil }
            if i == 0 {
                prefixStartIndex = index
            } else if index.utf16Offset(in: leadingText) == prefixStartIndex.utf16Offset(in: leadingText) + 1 {
                prefixStartIndex = index
            } else {
                return nil
            }
        }
        
        let wordRange = prefixStartIndex..<cursorRange.upperBound
        let word = leadingText[wordRange]
        
        let location = wordRange.lowerBound.utf16Offset(in: leadingText)
        let length = wordRange.upperBound.utf16Offset(in: word) - location
        let range = NSRange(location: location, length: length)
        
        let attributesInRange = self.attributedText.attributes(at: range.location, longestEffectiveRange: nil, in: range)
        for (key, value) in attributesInRange where key == .autocompleted && value is Bool {
            if value as! Bool {
                return nil
            }
        }
        return (String(prefix), String(word), range)
    }

    var caretRange: NSRange? {
        guard let selectedRange = self.selectedTextRange else { return nil }
        return NSRange(
            location: self.offset(from: self.beginningOfDocument, to: selectedRange.start),
            length: self.offset(from: selectedRange.start, to: selectedRange.end)
        )
    }
    
    func find(with delimiterSet: CharacterSet) -> Match? {
        guard let caretRange = self.caretRange, let cursorRange = Range(caretRange, in: self.text) else { return nil }
        var start: Int?
        for i in 0..<caretRange.location {
            
            if let value = self.attributedText.attribute(.autocompleted, at: i, effectiveRange: nil) as? Bool, value {
            } else if let c = self.text[self.text.index(from: i)].unicodeScalars.first, !delimiterSet.contains(c) {
                start = i
                break
            }
        }
        
        guard let index = start else { return nil }
        let word = self.text[self.text.index(from: index)..<cursorRange.upperBound]
        guard !word.isEmpty && word != " " else { return nil }
        return ("", String(word), NSRange(location: index, length: index + caretRange.location))
    }
    
}

extension NSAttributedString {

    func replacingCharacters(in range: NSRange, with attributedString: NSAttributedString) -> NSMutableAttributedString {
        let ns = NSMutableAttributedString(attributedString: self)
        ns.replaceCharacters(in: range, with: attributedString)
        return ns
    }
    
    static func += (lhs: inout NSAttributedString, rhs: NSAttributedString) {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        lhs = ns
    }
    
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        return NSAttributedString(attributedString: ns)
    }
    
}


