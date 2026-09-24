# 🪐 SwiftCxxLinkedList 🪢🧿

> **High-performance, hardened C++20 Doubly Linked List natively bridged to Swift 6 via Safe C++ Interoperability.** ⚡️🔮

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![C++20](https://img.shields.io/badge/C%2B%2B-20-00599C?style=flat&logo=c%2B%2B&logoColor=white)](https://isocpp.org)
[![Xcode 16+](https://img.shields.io/badge/Xcode-16%2B-1575F9?style=flat&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Tests](https://img.shields.io/badge/Tests-78%2F78%20Passed-2ea44f?style=flat&logo=githubactions&logoColor=white)]()
[![Bounds Safety](https://img.shields.io/badge/Hardened--Mode-_LIBCPP_FAST-8A2BE2?style=flat)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🪬 Overview

**SwiftCxxLinkedList** is a modern data structures library pairing a hardened **C++20 generic doubly linked list** with a zero-cost, type-safe **Swift 6 wrapper**.

By leveraging Apple's **Safe C++ Interoperability** guidelines, Clang bounds hardening (`-fbounds-safety` / `_LIBCPP_HARDENING_MODE_FAST`), and lifetime annotations, `SwiftCxxLinkedList` gives Swift developers native value semantics and standard library protocol conformances backed by the raw speed and memory layout control of modern C++.

---

## 🧬 Key Features

### 1. 🪐 C++20 Generic Core (`template<typename T> struct LinkedList`)
* **Bidirectional Chaining**: Node structure with symmetric pointers for constant-time head and tail operations.
* **C++20 Concepts & Constraints**: Constrained member functions (`requires std::is_copy_constructible_v<T>`) enabling compile-time support for **Move-Only** types.
* **Modern Ranges & Spans**: Initializer list, C++20 `std::ranges::input_range`, and `std::span` constructors with `__noescape` lifetime safety.
* **Three-Way Comparison**: Native `operator<=>` (spaceship operator) and `operator==` support for lexicographical comparison.

### 2. ⚡️ Copy-On-Write (COW) Memory Architecture
* **Implicit Sharing**: Internal storage managed via `std::shared_ptr<ListData>`.
* **Zero-Cost Copying**: Passing or assigning lists is an $\mathcal{O}(1)$ reference count increment.
* **Fast-Path $\mathcal{O}(1)$ Mutations**: In-place modification when unique ownership is verified (`use_count() == 1`).
* **Safe Detachment**: Deep clone (`ensureUnique()`) automatically executed on mutation when shared (`use_count() > 1`), guaranteeing absolute value semantics in Swift.

### 3. 🛡️ Apple Safe C++ Interop & Hardening
* **Bridging Annotations**: Annotated with `SWIFT_SAFE`, `SWIFT_SELF_CONTAINED`, `SWIFT_COPYABLE_IF(T)`, and `SWIFT_ESCAPABLE_IF(T)`.
* **Clang Bounds Hardening**: Built with `-Wunsafe-buffer-usage`, `_LIBCPP_HARDENING_MODE_FAST`, and boundary checks.
* **Safe Iterators**: Clamped iterator retreat (`--begin()` safely remains at `begin()`) and cross-list iterator invalidation protection.

### 4. 🪢 Full Swift Standard Library Protocol Conformance
Both `IntLinkedList` and `StringLinkedList` conform directly to:
* `Collection` & `BidirectionalCollection`
* `MutableCollection`
* `RangeReplaceableCollection`
* `ExpressibleByArrayLiteral`
* `CustomStringConvertible`
* `Equatable`, `Comparable`, `Hashable`

---

## 📊 Algorithmic Complexity

| Operation | C++ Method / Swift API | Time Complexity | Space Complexity |
| :--- | :--- | :---: | :---: |
| **Prepend / Append** | `prepend()`, `append()` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ |
| **Pop Front / Back** | `popFirst()`, `popLast()` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ |
| **Positional Access** | `list[index]` *(bidirectional search)* | $\mathcal{O}(n/2)$ | $\mathcal{O}(1)$ |
| **Iterator Subscript** | `list[iterator]` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ |
| **Iterator Insert / Erase** | `insert(it, val)`, `erase(it)` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ |
| **Range Erase** | `erase(first, last)` | $\mathcal{O}(k)$ | $\mathcal{O}(1)$ |
| **Copy Construction** | `let b = a` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ |
| **COW Mutation Detach**| `a[0] = 42` *(when shared)* | $\mathcal{O}(n)$ | $\mathcal{O}(n)$ |
| **Clear** | `clear()`, `removeAll()` | $\mathcal{O}(n)$ | $\mathcal{O}(1)$ |

---

## 💻 Usage & Code Examples

### 🍎 Swift 6: Idiomatic Collections & Value Semantics

```swift
import LinkedList
import CxxLinkedList

// 1. Array Literal Initialization
var list: IntLinkedList = [10, 20, 30, 40, 50]

// 2. Collection & Bidirectional Traversal
print("Elements count:", list.count) // 5
for value in list.reversed() {
    print(value) // 50, 40, 30, 20, 10
}

// 3. Functional Standard Algorithms
let sumOfSquares = list
    .filter { $0 > 20 }
    .map { $0 * $0 }
    .reduce(0, +)

// 4. Subscript Mutation & RangeReplaceableCollection
list[list.startIndex] = 99
list.append(60)
let _ = list.popFirst()

// 5. Copy-On-Write (COW) Isolation
var copy = list
copy.append(1000)

// 'list' and 'copy' are completely isolated!
print("Original:", list) // [20, 30, 40, 50, 60]
print("Copy:    ", copy) // [20, 30, 40, 50, 60, 1000]
```

---

### ⚙️ C++20: Raw Speed, Concepts & Span Utilities

```cpp
#include "LinkedList.hpp"
#include "LinkedListTypes.hpp"
#include <span>
#include <iostream>

int main() {
    // 1. C++20 Range & Span Interop
    int numbers[] = {1, 2, 3, 4, 5};
    IntLinkedList list = makeListFromSpan(std::span<const int32_t>(numbers));

    // 2. Fast In-Place Iterator Manipulation
    auto it = list.begin();
    ++it; // points to 2
    list.insert(it, 99); // O(1) insertion
    
    // 3. Bidirectional Iterators
    for (auto rit = list.crbegin(); rit != list.crend(); ++rit) {
        std::cout << *rit << " ";
    }
    std::cout << "\n";

    // 4. Spaceship Operator (<=>)
    IntLinkedList other = {1, 99, 2, 3, 4, 5};
    if (list == other) {
        std::cout << "Lists match perfectly!\n";
    }

    return 0;
}
```

---

## 📁 Package Architecture

```text
SwiftCxxLinkedList/
├── Package.swift                             # SPM Manifest (C++20 standard, SafeInteropWrappers)
├── Sources/
│   ├── CxxLinkedList/                        # C++20 Core Library
│   │   ├── include/
│   │   │   ├── LinkedList.hpp                # Template implementation with COW & Iterators
│   │   │   ├── LinkedListTypes.hpp           # Type aliases, Spans & SwiftInterop helpers
│   │   │   └── module.modulemap              # Clang module map for Cxx interop
│   │   └── CxxLinkedList.cpp                 # C++ target translation unit
│   └── LinkedList/                           # Swift Overlay
│       └── SwiftCxxLinkedList.swift          # Protocol conformances (Collection, COW, Literals)
└── Tests/
    ├── CxxLinkedListTests/                   # C++ Executable Test Runner
    │   └── main.cpp                          # Concepts, static assertions & stress tests
    ├── CxxLinkedListTestSupport/             # Lifecycle tracking & move-only helpers
    └── SwiftCxxLinkedListTests/              # Swift Testing Suite
        └── SwiftCxxLinkedListTests.swift     # 78 Unit tests with modern Swift Testing (@Test)
```

---

## 📦 Installation & Setup

### Swift Package Manager (SPM)

Add `SwiftCxxLinkedList` to your project's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ComeEdo/SwiftCxxLinkedList.git", from: "1.0.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "LinkedList", package: "SwiftCxxLinkedList")
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    )
]
```

### Supported Platforms
* **macOS**: 13.0+
* **iOS**: 16.0+
* **watchOS**: 9.0+
* **tvOS**: 16.0+
* **visionOS**: 1.0+

---

## 🧪 Testing & Verification

The codebase includes two independent test suites:

1. **Swift Testing Suite (`LinkedListTests`)**:
   - **78 / 78 Passing Tests** covering:
     - COW isolation across mutations, deletions, and extensions.
     - Higher-order algorithms (`filter`, `map`, `reduce`, `sorted`).
     - Real-world domain simulations (Polynomial multiplication, DNA codon sequencing).
     - Iterator invalidation safeguards and boundary conditions.
2. **C++ Concepts & Assertions (`CxxLinkedListTests`)**:
   - Static assertions verifying concept satisfaction for move-only and copyable types.
   - Lifetime tracker tracking allocations, constructions, destructions, and moves.

Execute tests via command line or Xcode:

```bash
swift test
```

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
