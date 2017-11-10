//
//  RegexHelper.swift
//  RegexHelper
//
//  Created by Louis Melahn on 5/5/16.
//  Edited 10/17/17
//  Copyright © 2016, 2017 Louis Melahn.
//
//  This file is licensed under the MIT license.
//

import Foundation

private extension String {
    
    func getCharacterFromIntIndex (_ i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        
        assert(i >= 0, "Index is too small")
        assert(i <= self.count, "Index is too large")
        
        return String(getCharacterFromIntIndex(i))
    }
    
    subscript (range: Range<Int>) -> String {
        
        return String(self[swiftRange(range)])
        
    }
}

// MARK - Adds a property returning the range representing the whole string.
private extension String {
    
    /// Returns the range of the whole string.
    var wholeString: Range<String.Index> {
        
        return self.startIndex ..< self.endIndex
        
    }
    
    /// Returns the range of the whole string, as an NSRange
    var wholeStringNsRange: NSRange {
        
        return NSRange(self.wholeString, in: self)
        
    }
    
}

// MARK - Adds methods to convert between Swift String ranges and `NSRange`s and ranges of integers
private extension String {
    
    /// Returns a Swift-String-compatible range based on a range of integers
    func swiftRange (_ intRange: Range<Int>) -> Range<String.Index> {
        
        assert (intRange.lowerBound >= 0, "Start index is too small (less than 0)")
        
        var inputStartIndex = intRange.lowerBound
        var inputEndIndex = intRange.upperBound
        let totalCharacters = self.count
        
        // If the start index is greater than the number of characters,
        // reduce the start index to the number characters, so as to
        // return an empty string.
        if inputStartIndex > totalCharacters {
            
            inputStartIndex = totalCharacters
            
        }
        
        // If the range rolls off the end of the string,
        // just return whatever much of the string you can.
        if inputEndIndex > totalCharacters {
            
            inputEndIndex = totalCharacters
            
        }
        
        let outputStartIndex = self.index(startIndex, offsetBy: inputStartIndex)
        
        let outputEndIndex = self.index(outputStartIndex,
                                        offsetBy: inputEndIndex - inputStartIndex)
        
        return Range(outputStartIndex ..< outputEndIndex)
        
    }
    
    /// Returns a Swift-String-compatible range, based on an NSRange
    func swiftRange (_ nsRange: NSRange) -> Range<String.Index>? {
        
        return Range(nsRange, in: self)
        
    }
    
    /// Returns an NSRange, based on a Swift-String-compatible range
    func nsRange(_ swiftRange: Range<String.Index>) -> NSRange {
        
        return NSRange(swiftRange, in: self)
        
    }
    
    /// Returns and NSRange, based on a range of integers
    func nsRange(_ intRange: Range<Int>) -> NSRange {
        
        let swiftRange = self.swiftRange(intRange)
        return nsRange(swiftRange)
        
    }
    
}

// MARK - adds the `matches` method to String, which takes (at a minimum)
//        a pattern to match, and returns an Match object with all the matches
public extension String {
    
    /// This overload uses the default options.
    /// - Parameters:
    ///   - regex: The NSRegularExpression object.
    ///
    /// - Returns:
    ///   An array of NSTextCheckingResult objects.
    private func nsMatches (_ regex: NSRegularExpression) -> [NSTextCheckingResult] {
        return self.nsMatches(regex, options: [])
    }
    
    /// This method returns all the matches that result from a given regular expression.
    /// It does low-level access to the NSRegularExpression API.
    ///
    /// - Parameters:
    ///   - regex: The NSRegularExpression object.
    ///   - options: The object containing the matching options.
    ///
    /// - Returns:
    ///   An array of NSTextCheckingResult objects.
    private func nsMatches (_ regex: NSRegularExpression, options: NSRegularExpression.MatchingOptions) -> [NSTextCheckingResult] {
        return regex.matches(in: self, options: options, range:  self.wholeStringNsRange)
    }
    
    fileprivate func validateRegex(_ pattern: String) -> Bool {
        
        do {
            
            let _ = try NSRegularExpression(pattern: pattern, options: [])
            return true
            
        } catch {
            
            return false
            
        }
        
    }
    
    /// Returns an Matches object based on a regex pattern.
    /// Uses the default regex and matching options.
    ///
    /// - Parameters:
    ///    - pattern: a string with the Regex pattern.
    ///
    /// - Returns:
    ///   A Matches object.
    ///
    public func matches(_ pattern: String) -> Matches {
        
        return matches(pattern, regexOptions: [], matchingOptions: [])
        
    }
    
    /// Returns a Matches object based on a regex pattern.
    /// Uses matching options, the the regex options need to be specified.
    /// Equivalent to `String.matches(`_pattern_`, regexOptions: `_options_`, [])`.
    ///
    /// - Parameters:
    ///    - pattern: a string with the regex pattern.
    ///    - regexOptions: the regular expression options
    ///
    /// - Returns:
    ///   A Matches object.
    ///
    public func matches(_ pattern: String, regexOptions: NSRegularExpression.Options) -> Matches {
        
        return matches(pattern, regexOptions: regexOptions, matchingOptions: [])
        
    }
    
    /// Returns an Matches object based on a regex pattern
    /// regex options, and matching options.
    ///
    /// - Parameters:
    ///    - pattern: a string with the regex pattern.
    ///    - regexOptions: the regular expression options
    ///    - matchingOptions: the the matching options
    ///
    /// - Returns:
    ///   A Matches object.
    ///
    public func matches(_ pattern: String,
                        regexOptions: NSRegularExpression.Options,
                        matchingOptions: NSRegularExpression.MatchingOptions) -> Matches {
        
        assert(validateRegex(pattern), "An invalid regex pattern was given: `\(pattern)`")
        
        let regex = try! NSRegularExpression(pattern: pattern, options: regexOptions)
        return matches(regex, options: matchingOptions)
    }
    
    
    /// Returns an Matches object based on a regex pattern.
    /// Uses the default options.
    ///
    /// - Parameters:
    ///    - pattern: a string with the regex pattern.
    ///
    /// - Returns:
    ///   A Matches object.
    ///
    public func matches(_ regex: NSRegularExpression) -> Matches {
        return matches(regex, options: [])
    }
    
    public func matches(_ regex: NSRegularExpression, options: NSRegularExpression.MatchingOptions) -> Matches {
        
        let nsMatches = self.nsMatches(regex, options: options)
        return Matches(matches: nsMatches, input: self)
        
    }
    
}

// MARK - Adds an `isMatchedBy` function to String for convenience.
public extension String {
    
    /// Tests if a string is matched by a given regular expression.
    /// This is the base implementation for all the rest.
    /// - Parameters:
    ///   - regex: an NSRegularExpression object
    ///   - matchingOptions: the matching options
    ///
    /// - Returns:
    /// Bool: `true` if `regex` matches the string (`self`); `false` otherwise.
    ///
    public func isMatchedBy(_ regex: NSRegularExpression, matchingOptions: NSRegularExpression.MatchingOptions) -> Bool {
        
        let matches = self.matches(regex, options: matchingOptions)
        
        if let _ = matches.first {
            
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    /// Tests if a string is matched by a given regular expression.
    /// Uses a regex with the default matching options.
    ///
    /// - Parameters:
    ///   - regex: an NSRegularExpression object
    ///
    /// - Returns:
    ///   Bool: `true` if `regex` matches the string (`self`); `false` otherwise.
    ///
    public func isMatchedBy(_ regex: NSRegularExpression) -> Bool {
        
        return isMatchedBy(regex, matchingOptions: [])
        
    }
    
    /// Tests if a string is matched by a given regular expression.
    /// Uses a string and allows configuring the regex and matching options.
    ///
    /// - Parameters:
    ///   - pattern: the String containing the pattern
    ///   - regexOptions: the regex options
    ///   - matchingOptions: the matching options
    ///
    /// - Returns:
    ///   Bool: `true` if `regex` matches the string (`self`); `false` otherwise.
    ///
    public func isMatchedBy(_ pattern: String,
                            regexOptions: NSRegularExpression.Options,
                            matchingOptions: NSRegularExpression.MatchingOptions) -> Bool {
        
        assert(validateRegex(pattern), "Invalid regex pattern given: \(pattern)")
        
        let regex = try! NSRegularExpression(pattern: pattern, options: regexOptions)
        
        return isMatchedBy(regex, matchingOptions: matchingOptions)
        
    }
    
    /// Tests if a string is matched by a given regular expression.
    /// Uses a string and allows configuring the regex options,
    /// but uses the default matching options
    ///
    /// - Parameters:
    ///   - pattern: the String containing the pattern
    ///   - regexOptions: the regex options
    ///
    /// - Returns:
    ///   Bool: `true` if `regex` matches the string (`self`); `false` otherwise.
    ///
    public func isMatchedBy(_ pattern: String, regexOptions: NSRegularExpression.Options) -> Bool {
        
        return isMatchedBy(pattern, regexOptions: regexOptions, matchingOptions: [])
        
    }
    
    /// Tests if a string is matched by a given regular expression.
    /// Uses a string with the default regex and matching options
    ///
    /// - Parameters:
    ///   - pattern: the String containing the pattern
    ///
    /// - Returns:
    ///   Bool: `true` if `regex` matches the string (`self`); `false` otherwise.
    ///
    public func isMatchedBy(_ pattern: String) -> Bool {
        
        return isMatchedBy(pattern, regexOptions: [], matchingOptions: [])
        
    }
    
}

// MARK - Adds a replaceAll function to String
public extension String {
    
    /// Does a replaceAll using an NSRegularExpression with the possibility
    /// of setting matching options.
    ///
    /// - Parameters:
    ///   - regex: the NSRegularExpression object representing what to search for.
    ///   - withTemplate: the template with which finds will be replaced.
    ///   - usingMatchingOptions: the matching options that will be used.
    ///
    /// - Returns: a new String with all replacements made.
    ///
    public func replaceAll (_ regex: NSRegularExpression,
                            withTemplate template: String,
                            usingMatchingOptions: NSRegularExpression.MatchingOptions)
        -> String {
            
            return regex.stringByReplacingMatches(in: self,
                                                  options: usingMatchingOptions,
                                                  range: self.wholeStringNsRange,
                                                  withTemplate: template)
            
    }
    
    /// Does a replaceAll using an NSRegularExpression object, with the default options.
    ///
    /// - Parameters:
    ///   - regex: the NSRegularExpression object representing what to search for
    ///   - withTemplate: the template with which finds will be replaced.
    ///
    /// - Returns: a new String with all replacements made.
    ///
    public func replaceAll(_ regex: NSRegularExpression,
                           withTemplate template: String)
        -> String {
            
            return replaceAll(regex,
                              withTemplate: template,
                              usingMatchingOptions: [])
            
    }
    
    /// Does a replaceAll using a String pattern, with the possibility of setting
    /// regex and matching options.
    ///
    /// - Parameters:
    ///   - pattern: the String representing what to search for
    ///   - withTemplate: the template with which finds will be replaced.
    ///   - usingRegexOptions: the regex options.
    ///   - usingMatchingOptions: the matching options.
    ///
    /// - Returns: a new String with all replacements made.
    ///
    public func replaceAll(_ pattern: String,
                           withTemplate: String,
                           usingRegexOptions: NSRegularExpression.Options,
                           usingMatchingOptions: NSRegularExpression.MatchingOptions) -> String {
        
        assert(validateRegex(pattern), "Invalid regex pattern given: \(pattern)")
        
        let regex = try! NSRegularExpression(pattern: pattern, options: usingRegexOptions)
        
        return replaceAll(regex, withTemplate: withTemplate, usingMatchingOptions: usingMatchingOptions)
        
    }
    
    /// Does a replaceAll using a String pattern, with the possibility of setting
    /// regex options, and using the default matching options.
    ///
    /// - Parameters:
    ///   - pattern: the String representing what to search for
    ///   - withTemplate: the template with which finds will be replaced.
    ///   - usingRegexOptions: the regex options.
    ///
    /// - Returns: a new String with all replacements made.
    ///
    public func replaceAll(_ pattern: String,
                           withTemplate: String,
                           usingRegexOptions: NSRegularExpression.Options) -> String {
        
        return replaceAll(pattern, withTemplate: withTemplate, usingRegexOptions: usingRegexOptions, usingMatchingOptions: [])
        
    }
    
    /// Does a replaceAll using a String pattern, with all the default options.
    ///
    /// - Parameters:
    ///   - pattern: the String representing what to search for
    ///   - withTemplate: the template with which finds will be replaced.
    ///
    /// - Returns: a new String with all replacements made.
    ///
    public func replaceAll(_ pattern: String, withTemplate: String) -> String {
        
        return replaceAll(pattern, withTemplate: withTemplate, usingRegexOptions: [])
        
    }
    
}

/// Represents the matches found after searching for a regular expression.
public struct Matches {
    
    fileprivate var nsMatches: [NSTextCheckingResult]
    fileprivate var input: String
    
    init(matches: [NSTextCheckingResult], input: String) {
        self.nsMatches = matches
        self.input = input
    }
}

// MARK - makes the matches type accessible by index
extension Matches : Collection {
    
    public typealias Index = Int
    
    public func index(after i: Int) -> Int {
        
        return i + 1
        
    }
    
    public var startIndex : Int { return 0 }
    
    public var endIndex : Int { return nsMatches.count }
    
    public subscript (i: Int) -> Match {
        
        return Match(match: nsMatches[i], input: input)
        
    }
    
}

// MARK - makes matches iterable
extension Matches : Sequence {
    
    public struct Iterator : IteratorProtocol {
        
        public typealias Element = Match
        
        private var matches : [NSTextCheckingResult]
        private var input: String
        private var index = 0
        
        init (matches: [NSTextCheckingResult], input: String) {
            self.matches = matches
            self.input = input
        }
        
        mutating public func next() -> Match? {
            let oldIndex = index
            index += 1
            
            if (oldIndex < matches.count) {
                return Match(match: matches[oldIndex], input: input)
            } else {
                return nil
            }
        }
        
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(matches: nsMatches, input: input)
    }
}

/// Represents each individual match.
///
public struct Match {
    
    /// Everything in the string previous to the match.
    public var pre: String {
        
        let range = input.swiftRange(nsMatch_.range)
        assert(range != nil, "A match was given, but the range it returned was nil")
        
        return String(input[input.startIndex..<range!.lowerBound])
        
    }
    
    /// Everything in the string after the match.
    public var post: String {
        
        let range = input.swiftRange(nsMatch_.range)
        assert(range != nil, "A match was given, but the range it returned was nil")
        
        return String(input[range!.upperBound..<input.endIndex])
        
    }
    
    /// The text actually matched.
    public var hit: String {
        
        let range = input.swiftRange(nsMatch_.range)
        assert(range != nil, "A match was given, but the range it returned was nil")
        
        return String(input[range!])
    }
    
    fileprivate var input: String
    fileprivate var nsMatch_: NSTextCheckingResult
    
    init (match: NSTextCheckingResult, input: String) {
        self.nsMatch_ = match
        self.input = input
    }
    
}

// MARK - makes the match type accessible by index
extension Match : Collection {
    
    public typealias Index = Int
    
    public func index(after i: Int) -> Int {
        
        return i + 1
        
    }
    
    public var startIndex : Int { return 0 }
    
    public var endIndex : Int { return nsMatch_.numberOfRanges }
    
    public subscript (i: Int) -> String {
        
        let range = input.swiftRange(nsMatch_.range(at: i))
        assert(range != nil, "An invalid index was given")
        
        return String(input[range!])
        
    }
    
}

extension Match : Sequence {
    
    public struct Iterator : IteratorProtocol {
        
        public typealias Element = String
        
        private var index = 0   // Note that one submatch is guaranteed.
        private var match: Match
        private let endIndex: Int
        
        init (match: Match, endIndex: Int) {
            
            self.match = match
            self.endIndex = endIndex
            
        }
        
        public mutating func next() -> Element? {
            
            if index == endIndex {
                
                return nil
                
            } else {
                
                let oldIndex = index
                index += 1
                return match[oldIndex]
                
            }
            
        }
        
    }
    
    public func makeIterator() -> Iterator {
        
        return Iterator(match: self, endIndex: count)
        
    }
    
}

// MARK - make it possible to use a Match as a variable by the print function
extension Match: CustomStringConvertible {
    
    public var description: String {
        
        return self.hit
        
    }
    
}

// MARK - returns a Range<String.Index> where the hit is.
extension Match {
    
    public var range: Range<String.Index> {
        
        let range = input.swiftRange(nsMatch_.range)
        assert(range != nil, "An invalid index was given")
        
        return range!
        
    }
    
}

// MARK - an extension to String that provides a regex-based splitter.
extension String {
    
    public struct Splitter: Sequence {
        
        let input: String
        let separator: String
        
        public init(input: String, usingSeparator separator: String) {
            
            self.input = input
            self.separator = separator
            
        }
        
        public struct Iterator : IteratorProtocol {
            
            public typealias Element = String
            
            let separator: String
            var input: String?
            
            init(input: String, separator: String) {
                
                self.input = input
                self.separator = separator
                
            }
            
            mutating public func next() -> Element? {
                
                if let (head, tail) = input?.splitFirst(usingSeparator: separator) {
                    
                    if let head = head {
                        
                        input = tail
                        return head
                        
                    } else {
                        
                        input = nil
                        return tail
                        
                    }
                    
                } else {
                    
                    return nil
                    
                }
            }
        }
        
        public func makeIterator() -> Iterator {
            
            return Iterator(input: input, separator: separator)
            
        }
        
    }
    
    /// This function will attempt to break a string in two
    /// at the first opportunity, eliminating the string that
    /// matches `sepearatorRegex`. Returns a tuple with the
    /// front part that has been "broken off" and the remaininder
    /// of the string. For instance,
    /// `"aaaa##aaaaa#aaa".splitFirst("#+")` will return `("aaaa", "aaaaa#aaa")`
    /// If one of the two pieces turns out to be empty, `splitFirst` will return
    /// `nil`. For example, if the separator pattern matches nothing, the method
    /// will return `(nil,` original-string`)`. If the match is at very end, the
    /// method will return `(`front-part-of-string`, nil)`. If the original string
    /// is empty, the method will return `(nil, nil)`.
    public func splitFirst(usingSeparator separator: String) -> (String?, String?) {
        
        if let match = self.matches(separator,
                                    regexOptions: [ .dotMatchesLineSeparators ]).first {
            
            let pre = match.pre
            let post = match.post
            
            return (pre=="" ? nil : pre, post=="" ? nil : post)
            
        } else {
            
            return (nil, self=="" ? nil : self)
            
        }
    }
    
    /// Returns a `String.Splitter` object that represents the pieces
    /// of a string that has been split according to a separator defined
    /// by a regex pattern. The `String.Splitter` can be used in a `for`
    /// loop or converted into an array by using the appropriate cast
    /// (e.g., `Array(mySplitter)`).
    public func split(usingSeprator separator: String) -> String.Splitter {
        
        return String.Splitter(input: self, usingSeparator: separator)
        
    }
    
    /// Returns a `String.Splitter` object that represents the pieces
    /// of a string that has been split according to white space (including
    /// newlines and tabs). The `String.Splitter` can be used in a `for` loop
    /// or converted into an array by using the appropriate cast
    /// (e.g., `Array(mySplitter)`).
    ///
    public var split: String.Splitter {
        
        return self.split(usingSeprator: "\\s+")
        
    }
    
}

extension String.Splitter: Collection {
    
    public typealias Index = Int
    
    public func index(after i: Int) -> Int {
        
        return i + 1
        
    }
    
    
    public var startIndex : Int { return 0 }
    
    public var endIndex : Int { var count = 0; for _ in self { count += 1 }; return count }
    
    public subscript (i: Int) -> String {
        
        var count = 0
        
        
        for string in self {
            
            if count==i {
                return string
            }
            
            count += 1
        }
        
        return ""
    }
}
