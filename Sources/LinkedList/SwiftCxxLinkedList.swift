//
//  LinkedList+Collection.swift
//  LinkedList
//
//  Created by Edoardo Frezzotti on 25/06/26.
//

import CxxLinkedList
import Foundation


// MARK: - IntLinkedList Collection & BidirectionalCollection Conformances

extension IntLinkedList: @retroactive @unsafe Collection, @retroactive @unsafe BidirectionalCollection, @retroactive @unsafe MutableCollection, @retroactive @unsafe RangeReplaceableCollection {
    public typealias Index = IntLinkedList.ConstIterator

    @inlinable
    public var startIndex: Index { SwiftInterop.startIndex(self) }

    @inlinable
    public var endIndex: Index { SwiftInterop.endIndex(self) }

    @inlinable
    public func index(after i: Index) -> Index { SwiftInterop.advance(i) }

    @inlinable
    public func index(before i: Index) -> Index { SwiftInterop.retreat(i) }

    @inlinable
    public subscript(position: Index) -> Int32 {
        get {
            return SwiftInterop.getElement(self, position)
        }
        set {
            SwiftInterop.setElement(&self, position, newValue)
        }
    }

    @inlinable
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, C.Element == Int32 {
        var insertPos = SwiftInterop.erase(&self, subrange.lowerBound, subrange.upperBound)
        for element in newElements {
            let inserted = SwiftInterop.insert(&self, insertPos, element)
            insertPos = SwiftInterop.advance(inserted)
        }
    }
}

// MARK: - StringLinkedList Collection & BidirectionalCollection Conformances

extension StringLinkedList: @retroactive @unsafe Collection, @retroactive @unsafe BidirectionalCollection, @retroactive @unsafe MutableCollection, @retroactive @unsafe RangeReplaceableCollection {
    public typealias Index = StringLinkedList.ConstIterator

    @inlinable
    public var startIndex: Index { SwiftInterop.startIndex(self) }

    @inlinable
    public var endIndex: Index { SwiftInterop.endIndex(self) }

    @inlinable
    public func index(after i: Index) -> Index { SwiftInterop.advance(i) }

    @inlinable
    public func index(before i: Index) -> Index { SwiftInterop.retreat(i) }

    @inlinable
    public subscript(position: Index) -> std.string {
        get {
            return SwiftInterop.getElement(self, position)
        }
        set {
            SwiftInterop.setElement(&self, position, newValue)
        }
    }

    @inlinable
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, C.Element == std.string {
        var insertPos = SwiftInterop.erase(&self, subrange.lowerBound, subrange.upperBound)
        for element in newElements {
            let inserted = SwiftInterop.insert(&self, insertPos, element)
            insertPos = SwiftInterop.advance(inserted)
        }
    }
}

// MARK: - Convenience Initializers & Swift Interop Helpers

public extension IntLinkedList {
    @inlinable
    mutating func clear() {
        self.removeAll()
    }
    
    @inlinable
    mutating func pop(_ index: Int) -> Int32 {
        return self.remove(at: index)
    }
    
    @inlinable
    @discardableResult
    mutating func erase(_ first: Index, _ last: Index) -> Index {
        return SwiftInterop.erase(&self, first, last)
    }
    
    @inlinable
    @discardableResult
    mutating func erase(_ iter: Index) -> Index {
        return SwiftInterop.erase(&self, iter)
    }
    
    @inlinable
    @discardableResult
    mutating func insert(_ iter: Index, _ value: Int32) -> Index {
        return SwiftInterop.insert(&self, iter, value)
    }
}

public extension StringLinkedList {
    @inlinable
    mutating func clear() {
        self.removeAll()
    }
    
    @inlinable
    mutating func pop(_ index: Int) -> std.string {
        return self.remove(at: index)
    }
    
    @inlinable
    @discardableResult
    mutating func erase(_ first: Index, _ last: Index) -> Index {
        return SwiftInterop.erase(&self, first, last)
    }
    
    @inlinable
    @discardableResult
    mutating func erase(_ iter: Index) -> Index {
        return SwiftInterop.erase(&self, iter)
    }
    
    @inlinable
    @discardableResult
    mutating func insert(_ iter: Index, _ value: std.string) -> Index {
        return SwiftInterop.insert(&self, iter, value)
    }
}

public extension IntLinkedList {
    @inlinable
    init<S: Sequence>(_ sequence: S) where S.Element == Int32 {
        self.init()
        for element in sequence {
            self.append(element)
        }
    }
}

public extension StringLinkedList {
    @inlinable
    init<S: Sequence>(_ sequence: S) where S.Element == std.string {
        self.init()
        for element in sequence {
            self.append(element)
        }
    }

    @inlinable
    init<S: Sequence>(strings sequence: S) where S.Element == String {
        self.init()
        for str in sequence {
            self.append(std.string(str))
        }
    }
}
// MARK: - ExpressibleByArrayLiteral

extension IntLinkedList: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int32...) {
        self.init()
        for element in elements {
            self.append(element)
        }
    }
}

extension StringLinkedList: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self.init()
        for element in elements {
            self.append(std.string(element))
        }
    }
}

// MARK: - CustomStringConvertible

extension IntLinkedList: @retroactive CustomStringConvertible {
    public var description: String {
        let elements = unsafe self.map { String($0) }
        return "[\(elements.joined(separator: ", "))]"
    }
}

extension StringLinkedList: @retroactive CustomStringConvertible {
    public var description: String {
        let elements = unsafe self.map { String($0) }
        return "[\(elements.joined(separator: ", "))]"
    }
}

// MARK: - Hashable Conformances

extension IntLinkedList: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hashValue())
    }
}

extension StringLinkedList: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hashValue())
    }
}
