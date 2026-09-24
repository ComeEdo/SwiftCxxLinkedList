//
//  main.cpp
//  CxxLinkedListTests
//
//  Created by Edoardo Frezzotti on 25/06/26.
//

#include <iostream>
#include "LinkedList.hpp"
#include "LinkedListTypes.hpp"
#include "LinkedListTestTypes.hpp"
#include <cassert>


template<typename T>
std::ostream& operator<<(std::ostream& os, const Node<T>& node) {
    os << node.value;
    return os;
}

std::ostream& operator<<(std::ostream& os, const MoveOnly& mo) {
    os << mo.value;
    return os;
}

template<typename T>
std::ostream& operator<<(std::ostream& os, const LinkedList<T>& list) noexcept {
    os << "[";
    bool first = true;
    
    for (const T& val : list) {
        if (!first) {
            os << ", ";
        } else {
            first = false;
        }
        os << val;
    }
    
    os << "]";
    return os;
}

// Concepts to check constraints
template<typename L>
concept can_copy_construct = requires(const L& other) {
    L(other);
};

template<typename L>
concept can_copy_assign = requires(L& a, const L& b) {
    a = b;
};

template<typename L, typename T>
concept can_append_const_ref = requires(L& list, const T& value) {
    list.append(value);
};

template<typename L, typename T>
concept can_prepend_const_ref = requires(L& list, const T& value) {
    list.prepend(value);
};

template<typename L>
concept can_extend_const_ref = requires(L& a, const L& b) {
    a.extend(b);
};

template<typename L, typename T>
concept can_insert_index_const_ref = requires(L& list, size_t index, const T& value) {
    list.insert(index, value);
};

template<typename L, typename T>
concept can_insert_iterator_const_ref = requires(L& list, typename L::Iterator iter, const T& value) {
    list.insert(iter, value);
};

// Concepts to check that move/rvalue overloads remain available
template<typename L, typename T>
concept can_append_rvalue = requires(L& list, T&& value) {
    list.append(std::move(value));
};

template<typename L, typename T>
concept can_prepend_rvalue = requires(L& list, T&& value) {
    list.prepend(std::move(value));
};

template<typename L, typename T>
concept can_insert_index_rvalue = requires(L& list, size_t index, T&& value) {
    list.insert(index, std::move(value));
};

template<typename L, typename T>
concept can_insert_iterator_rvalue = requires(L& list, typename L::Iterator iter, T&& value) {
    list.insert(iter, std::move(value));
};

// Test requires std::is_copy_constructible_v<T> constraints with MoveOnlyLinkedList at compile-time
static_assert(!can_copy_construct<MoveOnlyLinkedList>, "MoveOnlyLinkedList should not be copy constructible");
static_assert(!can_copy_assign<MoveOnlyLinkedList>, "MoveOnlyLinkedList should not be copy assignable");
static_assert(!can_append_const_ref<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should not allow append(const T&)");
static_assert(!can_prepend_const_ref<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should not allow prepend(const T&)");
static_assert(!can_extend_const_ref<MoveOnlyLinkedList>, "MoveOnlyLinkedList should not allow extend(const LinkedList<T>&)");
static_assert(!can_insert_index_const_ref<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should not allow insert(size_t, const T&)");
static_assert(!can_insert_iterator_const_ref<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should not allow insert(Iterator, const T&)");

// Test that move/rvalue operations are still accepted for MoveOnlyLinkedList
static_assert(can_append_rvalue<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should allow append(T&&)");
static_assert(can_prepend_rvalue<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should allow prepend(T&&)");
static_assert(can_insert_index_rvalue<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should allow insert(size_t, T&&)");
static_assert(can_insert_iterator_rvalue<MoveOnlyLinkedList, MoveOnly>, "MoveOnlyLinkedList should allow insert(Iterator, T&&)");

// Test that copy operations are accepted for copyable types (like LinkedList<int>)
static_assert(can_copy_construct<LinkedList<int>>, "LinkedList<int> should be copy constructible");
static_assert(can_copy_assign<LinkedList<int>>, "LinkedList<int> should be copy assignable");
static_assert(can_append_const_ref<LinkedList<int>, int>, "LinkedList<int> should allow append(const T&)");
static_assert(can_prepend_const_ref<LinkedList<int>, int>, "LinkedList<int> should allow prepend(const T&)");
static_assert(can_extend_const_ref<LinkedList<int>>, "LinkedList<int> should allow extend(const LinkedList<T>&)");
static_assert(can_insert_index_const_ref<LinkedList<int>, int>, "LinkedList<int> should allow insert(size_t, const T&)");
static_assert(can_insert_iterator_const_ref<LinkedList<int>, int>, "LinkedList<int> should allow insert(Iterator, const T&)");

int main(int argc, const char * argv[]) {
    std::cout << "Running C++ LinkedList Tests...\n";
    
    int b [] = {4, 1, 2};
    
    LinkedList<int> a1;
    a1.append(8);
    a1.extend(a1);
    a1.extend(b);
    a1.extend(std::span<const int>(b));
    
    // Test Safe Interop Span utilities
    auto spanList = makeListFromSpan(std::span<const int32_t>(b));
    assert(spanList.getCount() == 3);
    assert(sumSpan(std::span<const int32_t>(b)) == 7);
    
    LinkedList<int> a2 = {2};
    a2 = a1;
    
    // Iterator comparisons: non-const vs const (same direction)
    auto it = a1.begin();
    auto cit = a1.cbegin();
    assert(it == cit);
    assert(cit == it);
    
    // Test 2-parameter delegating constructor
    LinkedList<int>::Iterator itDerived(nullptr, it);
    LinkedList<int>::ConstIterator citDerived(nullptr, cit);
    (void)itDerived;
    (void)citDerived;
    
    // Reverse Iterator comparisons: non-const vs const (same direction)
    auto rit = a1.rbegin();
    auto crit = a1.crbegin();
    assert(rit == crit);
    assert(crit == rit);
    
    // Test safe decrement on begin() and rbegin() (clamping)
    LinkedList<int> decList = {10, 20, 30};
    auto itDec = decList.begin();
    --itDec; // Should safely remain at begin(), not slide to nullptr
    assert(itDec == decList.begin());
    assert(*itDec == 10);
    ++itDec;
    assert(*itDec == 20);

    auto ritDec = decList.rbegin();
    --ritDec; // Should safely remain at rbegin()
    assert(ritDec == decList.rbegin());
    assert(*ritDec == 30);
    ++ritDec;
    assert(*ritDec == 20);
    
    // Test operator<=> and operator== on LinkedList
    LinkedList<int> l1 = {1, 2, 3};
    LinkedList<int> l2 = {1, 2, 3};
    LinkedList<int> l3 = {1, 2, 4};
    
    assert(l1 == l2);
    assert(l1 != l3);
    assert((l1 <=> l3) < 0);
    assert((l3 <=> l1) > 0);
    
    // Test MoveOnlyLinkedList
    MoveOnlyLinkedList ml;
    ml.append(MoveOnly(42));
    ml.append(MoveOnly(84));
    assert(ml.getCount() == 2);
    
    MoveOnlyLinkedList ml2 = std::move(ml);
    assert(ml2.getCount() == 2);
    assert(ml.getCount() == 0);
    
    MoveOnly first = ml2.popFirst();
    assert(first.value == 42);
    assert(ml2.getCount() == 1);
    
    // Test Move Assignment
    MoveOnlyLinkedList ml3;
    ml3 = std::move(ml2);
    assert(ml3.getCount() == 1);
    assert(ml2.getCount() == 0);
    
    // Test Fast Path O(1) in-place modification via iterator
    LinkedList<int> fastPathList = {10, 20, 30};
    auto itFast = fastPathList.begin();
    fastPathList[itFast] = 99;
    assert(fastPathList[itFast] == 99);
    assert(fastPathList.getCount() == 3);
    
    // Test COW Slow Path modification via iterator
    LinkedList<int> cowShared = fastPathList;
    auto itCow = cowShared.begin();
    cowShared[itCow] = 777;
    // itCow è invalidato dal COW, serve un nuovo iteratore
    auto itCowNew = cowShared.begin();
    assert(cowShared[itCowNew] == 777);
    assert(fastPathList[itFast] == 99); // Isolation guaranteed!
    
    // Test COW modification via reverse iterator
    LinkedList<int> rCowOriginal = {10, 20, 30};
    LinkedList<int> rCowShared = rCowOriginal;
    auto rItCow = rCowShared.rbegin(); // points to 30 (tail)
    rCowShared[rItCow] = 999;
    // rItCow è invalidato dal COW, verifichiamo con accesso posizionale
    assert(rCowShared.popLast() == 999);
    assert(rCowOriginal.popLast() == 30); // Isolation guaranteed!
    
    // Test iterator insert under COW
    LinkedList<int> insOriginal = {1, 3};
    LinkedList<int> insShared = insOriginal;
    auto insIt = insShared.begin();
    ++insIt; // points to 3
    insShared.insert(insIt, 2);
    assert(insShared.getCount() == 3);
    assert(insShared[0] == 1 && insShared[1] == 2 && insShared[2] == 3);
    assert(insOriginal.getCount() == 2 && insOriginal[1] == 3); // Isolation guaranteed!
    
    // Test iterator erase under COW
    LinkedList<int> eraseOriginal = {10, 20, 30};
    LinkedList<int> eraseShared = eraseOriginal;
    auto eraseIt = eraseShared.begin();
    ++eraseIt; // points to 20
    auto afterErase = eraseShared.erase(eraseIt);
    assert(eraseShared.getCount() == 2);
    assert(*afterErase == 30);
    assert(eraseShared[0] == 10 && eraseShared[1] == 30);
    assert(eraseOriginal.getCount() == 3 && eraseOriginal[1] == 20); // Isolation guaranteed!
    
    // Test range erase (middle, start, end, all, empty range, and COW)
    {
        // 1. Middle range erase
        LinkedList<int> rList = {10, 20, 30, 40, 50};
        auto rFirst = rList.begin();
        ++rFirst; // points to 20
        auto rLast = rFirst;
        ++rLast;
        ++rLast; // points to 40
        auto retIt = rList.erase(rFirst, rLast); // erases 20, 30
        assert(rList.getCount() == 3);
        assert(*retIt == 40);
        assert(rList[0] == 10 && rList[1] == 40 && rList[2] == 50);

        // 2. Start range erase
        auto startIt = rList.erase(rList.begin(), retIt); // erases 10
        assert(rList.getCount() == 2);
        assert(*startIt == 40);
        assert(rList[0] == 40 && rList[1] == 50);

        // 3. End range erase
        auto endFirst = rList.begin();
        ++endFirst; // points to 50
        auto endRet = rList.erase(endFirst, rList.end()); // erases 50
        assert(rList.getCount() == 1);
        assert(endRet == rList.end());
        assert(rList[0] == 40);

        // 4. Empty range erase (no-op)
        auto noopRet = rList.erase(rList.begin(), rList.begin());
        assert(rList.getCount() == 1);
        assert(noopRet == rList.begin());

        // 5. Erase all
        auto allRet = rList.erase(rList.begin(), rList.end());
        assert(rList.getIsEmpty());
        assert(rList.getCount() == 0);
        assert(allRet == rList.end());

        // 6. Range erase with COW isolation
        LinkedList<int> cowOrig = {100, 200, 300, 400};
        LinkedList<int> cowCopy = cowOrig;
        auto cFirst = cowCopy.begin();
        ++cFirst; // 200
        auto cLast = cowCopy.end();
        --cLast; // 400
        cowCopy.erase(cFirst, cLast); // erases 200, 300
        assert(cowCopy.getCount() == 2);
        assert(cowCopy[0] == 100 && cowCopy[1] == 400);
        assert(cowOrig.getCount() == 4 && cowOrig[1] == 200 && cowOrig[2] == 300);

        // 7. Reverse iterator range erase
        LinkedList<int> revList = {1, 2, 3, 4, 5};
        auto rbFirst = revList.rbegin();
        ++rbFirst; // points to 4
        auto rbLast = rbFirst;
        ++rbLast;
        ++rbLast; // points to 2
        revList.erase(rbFirst, rbLast); // erases 4, 3 in reverse
        assert(revList.getCount() == 3);
        assert(revList[0] == 1 && revList[1] == 2 && revList[2] == 5);
    }
    
    // Test removeAt, removeFirst, removeLast under COW
    LinkedList<int> remOriginal = {10, 20, 30, 40};
    LinkedList<int> remShared = remOriginal;
    remShared.removeAt(1); // removes 20
    assert(remShared.getCount() == 3);
    assert(remShared[0] == 10 && remShared[1] == 30 && remShared[2] == 40);
    assert(remOriginal.getCount() == 4 && remOriginal[1] == 20);
    
    remShared.removeFirst(); // removes 10
    assert(remShared.getCount() == 2);
    assert(remShared[0] == 30);
    assert(remOriginal[0] == 10);
    
    remShared.removeLast(); // removes 40
    assert(remShared.getCount() == 1);
    assert(remShared[0] == 30);
    assert(remOriginal.getCount() == 4);
    
    // Test self-extend
    LinkedList<int> selfExt = {1, 2};
    selfExt.extend(selfExt);
    assert(selfExt.getCount() == 4);
    assert(selfExt[0] == 1 && selfExt[1] == 2 && selfExt[2] == 1 && selfExt[3] == 2);
    
    // Test clear() in-place (exclusive owner) and COW detach (shared owner)
    LinkedList<int> clearList = {1, 2, 3, 4, 5};
    clearList.clear();
    assert(clearList.getIsEmpty());
    assert(clearList.getCount() == 0);
    clearList.clear(); // Safe on already-empty list
    assert(clearList.getIsEmpty());
    clearList.append(100);
    assert(clearList.getCount() == 1 && clearList[0] == 100);

    // Test clear() with shared ownership (COW detach)
    LinkedList<int> sharedOriginal = {10, 20, 30};
    LinkedList<int> sharedCopy = sharedOriginal;
    sharedCopy.clear();
    assert(sharedCopy.getIsEmpty());
    assert(sharedOriginal.getCount() == 3 && sharedOriginal[0] == 10); // Original untouched
    
    // Test compilation error constraint (requires std::is_copy_constructible_v<T>)
    // The line below tries to append 'first' (an lvalue of MoveOnly) which requires copy-construction.
    // This will cause a compilation error because MoveOnly is not copy-constructible.
    //ml2.append(first);
    
    std::cout << std::endl << "All C++ Tests Passed Successfully!" << std::endl;
    return EXIT_SUCCESS;
}
