//
//  LinkedListTestTypes.hpp
//  CxxLinkedList
//
//  Created by Edoardo Frezzotti on 25/06/26.
//

#pragma once
#include "LinkedList.hpp"
#include <atomic>


// MARK: - Test & Benchmark Helper Types

struct SWIFT_NONCOPYABLE SWIFT_ESCAPABLE MoveOnly {
    int value;
    MoveOnly(int val) : value(val) {}
    MoveOnly(const MoveOnly&) = delete;
    MoveOnly& operator=(const MoveOnly&) = delete;
    MoveOnly(MoveOnly&&) noexcept = default;
    MoveOnly& operator=(MoveOnly&&) noexcept = default;
};

using MoveOnlyLinkedList = LinkedList<MoveOnly>;        // da non usare in Swift fino a supporto move-only

struct SWIFT_ESCAPABLE LifecycleTracker {
private:
    inline static std::atomic<int> _constructCount{0};
    inline static std::atomic<int> _destructCount{0};
    inline static std::atomic<int> _copyCount{0};
    inline static std::atomic<int> _moveCount{0};

public:
    int value;

    static int getConstructCount() noexcept { return _constructCount.load(std::memory_order_relaxed); }
    static int getDestructCount() noexcept { return _destructCount.load(std::memory_order_relaxed); }
    static int getCopyCount() noexcept { return _copyCount.load(std::memory_order_relaxed); }
    static int getMoveCount() noexcept { return _moveCount.load(std::memory_order_relaxed); }
    
    LifecycleTracker(int val = 0) : value(val) {
        _constructCount.fetch_add(1, std::memory_order_relaxed);
    }
    
    LifecycleTracker(const LifecycleTracker& other) : value(other.value) {
        _constructCount.fetch_add(1, std::memory_order_relaxed);
        _copyCount.fetch_add(1, std::memory_order_relaxed);
    }
    
    LifecycleTracker& operator=(const LifecycleTracker& other) {
        value = other.value;
        _copyCount.fetch_add(1, std::memory_order_relaxed);
        return *this;
    }
    
    LifecycleTracker(LifecycleTracker&& other) noexcept : value(std::move(other.value)) {
        _constructCount.fetch_add(1, std::memory_order_relaxed);
        _moveCount.fetch_add(1, std::memory_order_relaxed);
    }
    
    LifecycleTracker& operator=(LifecycleTracker&& other) noexcept {
        value = std::move(other.value);
        _moveCount.fetch_add(1, std::memory_order_relaxed);
        return *this;
    }
    
    ~LifecycleTracker() {
        _destructCount.fetch_add(1, std::memory_order_relaxed);
    }
    
    static void reset() noexcept {
        _constructCount.store(0, std::memory_order_relaxed);
        _destructCount.store(0, std::memory_order_relaxed);
        _copyCount.store(0, std::memory_order_relaxed);
        _moveCount.store(0, std::memory_order_relaxed);
    }
};

using LifecycleLinkedList = LinkedList<LifecycleTracker>;
