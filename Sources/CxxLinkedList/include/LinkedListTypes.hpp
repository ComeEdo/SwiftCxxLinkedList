//
//  LinkedListTypes.hpp
//  CxxLinkedList
//
//  Created by Edoardo Frezzotti on 25/06/26.
//

#pragma once
#include "LinkedList.hpp"
#include <span>
#include <cstdint>
#include <lifetimebound.h>


// MARK: - Convenience Type Aliases

using IntLinkedList = LinkedList<int32_t>;
using StringLinkedList = LinkedList<std::string>;

using IntSpan = std::span<const int32_t>;

// MARK: - Safe Interop Span & Bounds Safety Utilities

inline int32_t sumSpan(IntSpan values __noescape) {
    int32_t sum = 0;
    for (int32_t val : values) {
        sum += val;
    }
    return sum;
}

inline IntLinkedList makeListFromSpan(IntSpan source __noescape) {
    IntLinkedList list;
    for (int32_t val : source) {
        list.append(val);
    }
    return list;
}
// MARK: - Swift Collection O(1) Helpers

namespace SwiftInterop {
    SWIFT_SAFE inline IntLinkedList::ConstIterator startIndex(const IntLinkedList& list) { return list.cbegin(); }
    SWIFT_SAFE inline IntLinkedList::ConstIterator endIndex(const IntLinkedList& list) { return list.cend(); }
    SWIFT_SAFE inline IntLinkedList::ConstIterator advance(IntLinkedList::ConstIterator it) { return ++it; }
    SWIFT_SAFE inline IntLinkedList::ConstIterator retreat(IntLinkedList::ConstIterator it) { return --it; }
    SWIFT_SAFE inline int32_t getElement(const IntLinkedList& list, IntLinkedList::ConstIterator it) { return list[it]; }
    SWIFT_SAFE inline void setElement(IntLinkedList& list, IntLinkedList::ConstIterator it, int32_t val) { list[it] = val; }
    SWIFT_SAFE inline IntLinkedList::ConstIterator erase(IntLinkedList& list, IntLinkedList::ConstIterator first, IntLinkedList::ConstIterator last) { return list.erase(first, last); }
    SWIFT_SAFE inline IntLinkedList::ConstIterator erase(IntLinkedList& list, IntLinkedList::ConstIterator it) { return list.erase(it); }
    SWIFT_SAFE inline IntLinkedList::ConstIterator insert(IntLinkedList& list, IntLinkedList::ConstIterator it, int32_t val) { return list.insert(it, val); }

    SWIFT_SAFE inline StringLinkedList::ConstIterator startIndex(const StringLinkedList& list) { return list.cbegin(); }
    SWIFT_SAFE inline StringLinkedList::ConstIterator endIndex(const StringLinkedList& list) { return list.cend(); }
    SWIFT_SAFE inline StringLinkedList::ConstIterator advance(StringLinkedList::ConstIterator it) { return ++it; }
    SWIFT_SAFE inline StringLinkedList::ConstIterator retreat(StringLinkedList::ConstIterator it) { return --it; }
    SWIFT_SAFE inline std::string getElement(const StringLinkedList& list, StringLinkedList::ConstIterator it) { return list[it]; }
    SWIFT_SAFE inline void setElement(StringLinkedList& list, StringLinkedList::ConstIterator it, const std::string& val) { list[it] = val; }
    SWIFT_SAFE inline StringLinkedList::ConstIterator erase(StringLinkedList& list, StringLinkedList::ConstIterator first, StringLinkedList::ConstIterator last) { return list.erase(first, last); }
    SWIFT_SAFE inline StringLinkedList::ConstIterator erase(StringLinkedList& list, StringLinkedList::ConstIterator it) { return list.erase(it); }
    SWIFT_SAFE inline StringLinkedList::ConstIterator insert(StringLinkedList& list, StringLinkedList::ConstIterator it, const std::string& val) { return list.insert(it, val); }
}
