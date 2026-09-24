//
//  LinkedList.hpp
//  CxxLinkedList
//
//  Created by Edoardo Frezzotti on 25/06/26.
//

#pragma once
#include <string>
#include <swift/bridging>
//gli include sono giusti, non serve aggiungerne altri


template<typename T> struct Node;

template<typename T>
struct SWIFT_SAFE SWIFT_SELF_CONTAINED SWIFT_COPYABLE_IF(T) SWIFT_ESCAPABLE_IF(T)
SWIFT_CONFORMS_TO_PROTOCOL(Cxx.CxxSequence)
SWIFT_CONFORMS_TO_PROTOCOL(Swift.Comparable)
SWIFT_CONFORMS_TO_PROTOCOL(Swift.Equatable)
LinkedList {
public:
    template <bool IsConst, bool IsReverse>
    struct SWIFT_SAFE SWIFT_CONFORMS_TO_PROTOCOL(Cxx.UnsafeCxxInputIterator) BasicIterator;

    using Iterator = BasicIterator<false, false>;
    using ConstIterator = BasicIterator<true, false>;
    using ReverseIterator = BasicIterator<false, true>;
    using ConstReverseIterator = BasicIterator<true, true>;

    using value_type = T;
    using reference = T&;
    using const_reference = const T&;
    using size_type = size_t;
    using difference_type = std::ptrdiff_t;

private:
    struct ListData {
        Node<T>* head;
        Node<T>* tail;
        size_t length;
        
        ListData() : head(nullptr), tail(nullptr), length(0) {}
        
        ~ListData() {
            Node<T>* current = head;
            while (current) {
                Node<T>* next = current->getNext();
                delete current;
                current = next;
            }
        }
    };
    
    std::shared_ptr<ListData> data;

    // Fast Single-Line Internal Accessors
    Node<T>*& head() { return data->head; }
    Node<T>* const& head() const { return data->head; }
    Node<T>*& tail() { return data->tail; }
    Node<T>* const& tail() const { return data->tail; }
    size_t& length() { return data->length; }
    const size_t& length() const { return data->length; }

    // MARK: - Private Helpers (Signatures)
    template<typename U = T>
    void ensureUnique();

    Node<T>* getNodeAt(size_t index);
    const Node<T>* getNodeAt(size_t index) const;
    void removeInternal(Node<T>* target);

    template <typename U>
    void appendInternal(U&& value);

    template <typename U>
    void prependInternal(U&& value);

    template <typename U>
    void insertInternal(size_t index, U&& value);

    T extractAndRemove(Node<T>* target);

    template <bool IsConst, bool IsReverse>
    Node<T>* unwrap(BasicIterator<IsConst, IsReverse> iter) const noexcept;

    template <bool IsConst, bool IsReverse>
    void validateIterator(const BasicIterator<IsConst, IsReverse>& iter) const;

    template <bool IsConst, bool IsReverse, typename U>
    BasicIterator<IsConst, IsReverse> insertAtIterator(BasicIterator<IsConst, IsReverse> iter, U&& value);

    friend struct Node<T>;
    
public:
    // MARK: - Constructors & Destructor
    LinkedList() noexcept SWIFT_SAFE : data(std::make_shared<ListData>()) {}
    LinkedList(const LinkedList& other) requires std::is_copy_constructible_v<T> = default;
    LinkedList(std::initializer_list<T> init) SWIFT_SAFE : LinkedList() {
        for (const T& value : init) {
            append(value);
        }
    }
    LinkedList(LinkedList&& other) noexcept SWIFT_SAFE : data(std::exchange(other.data, std::make_shared<ListData>())) {}
    template <std::ranges::input_range R>
    requires (std::convertible_to<std::ranges::range_reference_t<R>, T> && !std::same_as<std::remove_cvref_t<R>, LinkedList<T>>)
    explicit LinkedList(R&& range) SWIFT_SAFE : LinkedList() {
        for (auto&& value : range) {
            append(std::forward<decltype(value)>(value));
        }
    }
    ~LinkedList() noexcept = default;
    
    // MARK: - Assignment Operators
    LinkedList& operator=(const LinkedList& other) requires std::is_copy_constructible_v<T> = default;
    LinkedList& operator=(LinkedList&& other) noexcept SWIFT_SAFE;

    // MARK: - Element Access & Subscripts
    T& operator[](size_t index) SWIFT_SAFE { ensureUnique(); return getNodeAt(index)->value; }
    const T& operator[](size_t index) const SWIFT_SAFE { return getNodeAt(index)->value; }
    
    template <bool IsConst, bool IsReverse>
    const T& operator[](BasicIterator<IsConst, IsReverse> iter) const SWIFT_SAFE;
    template <bool IsConst, bool IsReverse>
    T& operator[](BasicIterator<IsConst, IsReverse> iter) SWIFT_SAFE;

    // MARK: - Capacity & Status
    [[nodiscard]] explicit operator bool() const noexcept SWIFT_SAFE { return length() > 0; }
    [[nodiscard]] bool operator!() const noexcept SWIFT_SAFE { return length() == 0; }
    [[nodiscard]] size_t getCount() const noexcept SWIFT_COMPUTED_PROPERTY SWIFT_SAFE { return length(); }
    [[nodiscard]] bool getIsEmpty() const noexcept SWIFT_COMPUTED_PROPERTY SWIFT_SAFE { return length() == 0; }
    void clear() SWIFT_NAME(removeAll()) SWIFT_SAFE;

    // MARK: - Swift Hashable Support
    [[nodiscard]] size_t hashValue() const noexcept SWIFT_SAFE;

    // MARK: - Comparisons
    [[nodiscard]] bool operator==(const LinkedList& other) const SWIFT_SAFE;
    [[nodiscard]] bool operator<(const LinkedList& other) const requires std::totally_ordered<T> SWIFT_SAFE;
    auto operator<=>(const LinkedList& other) const SWIFT_SAFE;

    // MARK: - Iterators
    [[nodiscard]] Iterator begin() noexcept SWIFT_SAFE { return Iterator(head(), data.get(), 0); }
    [[nodiscard]] Iterator end() noexcept SWIFT_SAFE { return Iterator(nullptr, data.get(), length()); }
    [[nodiscard]] ConstIterator begin() const noexcept SWIFT_SAFE { return ConstIterator(head(), data.get(), 0); }
    [[nodiscard]] ConstIterator end() const noexcept SWIFT_SAFE { return ConstIterator(nullptr, data.get(), length()); }
    [[nodiscard]] ConstIterator cbegin() const noexcept SWIFT_SAFE { return ConstIterator(head(), data.get(), 0); }
    [[nodiscard]] ConstIterator cend() const noexcept SWIFT_SAFE { return ConstIterator(nullptr, data.get(), length()); }
    [[nodiscard]] ReverseIterator rbegin() noexcept SWIFT_SAFE { return ReverseIterator(tail(), data.get(), 0); }
    [[nodiscard]] ReverseIterator rend() noexcept SWIFT_SAFE { return ReverseIterator(nullptr, data.get(), length()); }
    [[nodiscard]] ConstReverseIterator rbegin() const noexcept SWIFT_SAFE { return ConstReverseIterator(tail(), data.get(), 0); }
    [[nodiscard]] ConstReverseIterator rend() const noexcept SWIFT_SAFE { return ConstReverseIterator(nullptr, data.get(), length()); }
    [[nodiscard]] ConstReverseIterator crbegin() const noexcept SWIFT_SAFE { return ConstReverseIterator(tail(), data.get(), 0); }
    [[nodiscard]] ConstReverseIterator crend() const noexcept SWIFT_SAFE { return ConstReverseIterator(nullptr, data.get(), length()); }

    // MARK: - Index Navigation Helpers
    ConstIterator indexBefore(ConstIterator iter) const SWIFT_SAFE;
    ConstIterator indexAfter(ConstIterator iter) const SWIFT_SAFE;

    // MARK: - Modifiers: Append & Prepend
    void append(const T& value) requires std::is_copy_constructible_v<T> SWIFT_SAFE;
    void append(T&& value) SWIFT_SAFE;
    void prepend(const T& value) requires std::is_copy_constructible_v<T> SWIFT_SAFE;
    void prepend(T&& value) SWIFT_SAFE;

    // MARK: - Modifiers: Extend
    void extend(const LinkedList<T>& other) requires std::is_copy_constructible_v<T> SWIFT_SAFE;
    void extend(LinkedList<T>&& other) SWIFT_SAFE;
    void extend(std::initializer_list<T> init) SWIFT_SAFE;
    template <std::ranges::input_range R>
    requires (std::convertible_to<std::ranges::range_reference_t<R>, T> && !std::same_as<std::remove_cvref_t<R>, LinkedList<T>>)
    void extend(R&& range) SWIFT_SAFE;

    // MARK: - Modifiers: Insert
    void insert(size_t index, const T& value) requires std::is_copy_constructible_v<T> SWIFT_SAFE;
    void insert(size_t index, T&& value) SWIFT_SAFE;
    template <bool IsConst, bool IsReverse>
    BasicIterator<IsConst, IsReverse> insert(BasicIterator<IsConst, IsReverse> iter, const T& value) requires std::is_copy_constructible_v<T> SWIFT_SAFE;
    template <bool IsConst, bool IsReverse>
    BasicIterator<IsConst, IsReverse> insert(BasicIterator<IsConst, IsReverse> iter, T&& value) SWIFT_SAFE;

    // MARK: - Modifiers: Pop & Remove
    T popFirst() SWIFT_SAFE;
    T popLast() SWIFT_SAFE;
    T pop() SWIFT_SAFE { return popLast(); }
    SWIFT_NAME(remove(at:)) T pop(size_t index) SWIFT_SAFE;
    void removeAt(size_t index) SWIFT_SAFE { ensureUnique(); removeInternal(getNodeAt(index)); }
    void removeFirst() SWIFT_SAFE;
    void removeLast() SWIFT_SAFE;

    // MARK: - Modifiers: Erase
    template <bool IsConst, bool IsReverse>
    BasicIterator<IsConst, IsReverse> erase(BasicIterator<IsConst, IsReverse> iter) SWIFT_SAFE;
    template <bool IsConst, bool IsReverse>
    BasicIterator<IsConst, IsReverse> erase(BasicIterator<IsConst, IsReverse> first, BasicIterator<IsConst, IsReverse> last) SWIFT_SAFE;
};

template<typename T>
struct Node {
private:
    Node* previous;
    Node* next;
    
public:
    T value;
    
    Node(const Node&) = delete;
    Node& operator=(const Node&) = delete;
    Node(Node&&) = delete;
    Node& operator=(Node&&) = delete;
    
    Node (const T& value) requires std::is_copy_constructible_v<T> : value(value), previous(nullptr), next(nullptr) {}
    Node (const T& value, Node* previous, Node* next) requires std::is_copy_constructible_v<T> : Node(value) {
        setPrevious(previous);
        setNext(next);
    }
    
    Node(T&& value) noexcept(std::is_nothrow_move_constructible_v<T>) : value(std::move(value)), previous(nullptr), next(nullptr) {}
    Node(T&& value, Node* previous, Node* next) : Node(std::move(value)) {
        setPrevious(previous);
        setNext(next);
    }
    
    [[nodiscard]] Node* getPrevious() const noexcept SWIFT_COMPUTED_PROPERTY { return previous; }
    [[nodiscard]] Node* getNext() const noexcept SWIFT_COMPUTED_PROPERTY { return next; }
    
private:
    void setPrevious(Node* previous) noexcept {
        if (this->previous) {
            this->previous->next = nullptr;
        }
        if (previous) {
            if (previous->next) {
                previous->next->previous = nullptr;
            }
            previous->next = this;
        }
        this->previous = previous;
    }
    
    void setNext(Node* next) noexcept {
        if (this->next) {
            this->next->previous = nullptr;
        }
        if (next) {
            if (next->previous) {
                next->previous->next = nullptr;
            }
            next->previous = this;
        }
        this->next = next;
    }
    
    friend void LinkedList<T>::removeInternal(Node<T>* target);
    friend void LinkedList<T>::extend(LinkedList<T>&& other);
};

template<typename T>
template <bool IsConst, bool IsReverse>
struct SWIFT_SAFE SWIFT_CONFORMS_TO_PROTOCOL(Cxx.UnsafeCxxInputIterator) SWIFT_CONFORMS_TO_PROTOCOL(Swift.Comparable) LinkedList<T>::BasicIterator {
private:
    using NodePtr = std::conditional_t<IsConst, const Node<T>*, Node<T>*>;
    
    NodePtr current;
    const ListData* listData;
    size_t offset;
    
    friend struct LinkedList<T>;
    //template <bool C, bool R> friend struct BasicIterator; //su mac funziona senza
    
public:
    using value_type = T;
    using reference = std::conditional_t<IsConst, const T&, T&>;
    using pointer = std::conditional_t<IsConst, const T*, T*>;
    using iterator_category = std::bidirectional_iterator_tag;
    using iterator_concept  = std::bidirectional_iterator_tag;
    using difference_type = std::ptrdiff_t;
    
    BasicIterator() noexcept : current(nullptr), listData(nullptr), offset(0) {}
    BasicIterator(NodePtr node, const ListData* listData, size_t offset) noexcept : current(node), listData(listData), offset(offset) {}
    
    template <bool OtherConst>
    BasicIterator(NodePtr node, const ListData* data, const BasicIterator<OtherConst, IsReverse>& other) noexcept : current(node), listData(data), offset(other.offset) {}
    
    template <bool OtherConst>
    BasicIterator(NodePtr node, const BasicIterator<OtherConst, IsReverse>& other) noexcept : BasicIterator(node, other.listData, other) {}
    
    template <bool C = IsConst, typename = std::enable_if_t<C>>
    BasicIterator(const BasicIterator<false, IsReverse>& other) noexcept : BasicIterator(other.current, other) {}
    
    reference operator*() const {
        if (!current) {
            throw std::out_of_range("Tentativo di dereferenziare un iteratore non valido o end()!");
        }
        return current->value;
    }
    pointer operator->() const {
        if (!current) {
            throw std::out_of_range("Tentativo di dereferenziare un iteratore non valido o end()!");
        }
        return &(current->value);
    }
    
    BasicIterator& operator++() noexcept {
        if (current) {
            if constexpr (IsReverse) {
                current = current->getPrevious();
            } else {
                current = current->getNext();
            }
            ++offset;
        }
        return *this;
    }
    
    BasicIterator operator++(int) noexcept {
        BasicIterator tmp = *this;
        ++(*this);
        return tmp;
    }
    
    BasicIterator& operator--() noexcept {
        if (current) {
            NodePtr prevNode = nullptr;
            if constexpr (IsReverse) {
                prevNode = current->getNext();
            } else {
                prevNode = current->getPrevious();
            }
            if (prevNode) {
                current = prevNode;
                if (offset > 0) {
                    --offset;
                }
            }
        } else if (listData) {
            if constexpr (IsReverse) {
                current = listData->head;
            } else {
                current = listData->tail;
            }
            if (current && offset > 0) {
                --offset;
            }
        }
        return *this;
    }
    
    BasicIterator operator--(int) noexcept {
        BasicIterator tmp = *this;
        --(*this);
        return tmp;
    }
    
    bool operator==(const BasicIterator& other) const noexcept {
        return listData == other.listData && current == other.current;
    }
    
    template <bool OtherConst>
    bool operator==(const BasicIterator<OtherConst, IsReverse>& other) const noexcept {
        return listData == other.listData && current == other.current;
    }
    
    bool operator<(const BasicIterator& other) const noexcept {
        if (listData == other.listData) {
            if (current == other.current) {
                return false;
            } else {
                return offset < other.offset;
            }
        } else {
            return listData < other.listData;
        }
    }
    
    template <bool OtherConst>
    bool operator<(const BasicIterator<OtherConst, IsReverse>& other) const noexcept {
        if (listData == other.listData) {
            if (current == other.current) {
                return false;
            } else {
                return offset < other.offset;
            }
        } else {
            return listData < other.listData;
        }
    }
};

// =============================================================================
// MARK: - Out-of-Line Definitions (in matching declaration order)
// =============================================================================

// MARK: - Private Helpers

template<typename T>
template<typename U>
inline void LinkedList<T>::ensureUnique() {
    if (data.use_count() > 1) {
        if constexpr (std::is_copy_constructible_v<U>) {
            auto newData = std::make_shared<ListData>();
            Node<U>* current = data->head;
            while (current) {
                if (newData->tail) {
                    newData->tail = new Node<U>(current->value, newData->tail, nullptr);
                } else {
                    newData->head = newData->tail = new Node<U>(current->value, nullptr, nullptr);
                }
                newData->length++;
                current = current->getNext();
            }
            data = newData;
        } else {
            throw std::logic_error("Cannot copy non-copyable type");
        }
    }
}

template<typename T>
inline Node<T>* LinkedList<T>::getNodeAt(size_t index) {
    if (index >= length()) {
        throw std::out_of_range("Indice fuori dai limiti della lista!");
    }
    
    Node<T>* current = nullptr;
    
    if (index < length() / 2) {
        current = head();
        for (size_t i = 0; i < index; ++i) {
            current = current->getNext();
        }
    } else {
        current = tail();
        for (size_t i = length() - 1; i > index; --i) {
            current = current->getPrevious();
        }
    }
    return current;
}

template<typename T>
inline const Node<T>* LinkedList<T>::getNodeAt(size_t index) const {
    return const_cast<LinkedList*>(this)->getNodeAt(index);
}

template<typename T>
inline void LinkedList<T>::removeInternal(Node<T>* target) {
    ensureUnique();
    if (!target) return;
    
    if (target == head()) { head() = target->getNext(); }
    if (target == tail()) { tail() = target->getPrevious(); }
    
    if (target->getPrevious()) {
        target->getPrevious()->setNext(target->getNext());
    } else if (target->getNext()) {
        target->setNext(nullptr);
    }
    delete target;
    length() -= 1;
}

template<typename T>
template <typename U>
inline void LinkedList<T>::appendInternal(U&& value) {
    ensureUnique();
    if (tail()) {
        tail() = new Node<T>(std::forward<U>(value), tail(), nullptr);
    } else {
        head() = tail() = new Node<T>(std::forward<U>(value), nullptr, nullptr);
    }
    length() += 1;
}

template<typename T>
template <typename U>
inline void LinkedList<T>::prependInternal(U&& value) {
    ensureUnique();
    if (head()) {
        head() = new Node<T>(std::forward<U>(value), nullptr, head());
    } else {
        head() = tail() = new Node<T>(std::forward<U>(value), nullptr, nullptr);
    }
    length() += 1;
}

template<typename T>
template <typename U>
inline void LinkedList<T>::insertInternal(size_t index, U&& value) {
    ensureUnique();
    if (index == 0) {
        prependInternal(std::forward<U>(value));
    } else if (index == length()) {
        appendInternal(std::forward<U>(value));
    } else {
        Node<T>* current = getNodeAt(index);
        new Node<T>(std::forward<U>(value), current->getPrevious(), current);
        length() += 1;
    }
}

template<typename T>
inline T LinkedList<T>::extractAndRemove(Node<T>* target) {
    T value = std::move(target->value);
    removeInternal(target);
    return value;
}

template<typename T>
template <bool IsConst, bool IsReverse>
inline Node<T>* LinkedList<T>::unwrap(BasicIterator<IsConst, IsReverse> iter) const noexcept {
    return const_cast<Node<T>*>(iter.current);
}

template<typename T>
template <bool IsConst, bool IsReverse>
inline void LinkedList<T>::validateIterator(const BasicIterator<IsConst, IsReverse>& iter) const {
    if (iter.listData != data.get()) {
        throw std::invalid_argument("L'indice appartiene a un'altra lista o è stato invalidato!");
    }
    if (!iter.current) {
        throw std::out_of_range("Indice fuori dai limiti della lista!");
    }
}

template<typename T>
template <bool IsConst, bool IsReverse, typename U>
inline auto LinkedList<T>::insertAtIterator(BasicIterator<IsConst, IsReverse> iter, U&& value) -> BasicIterator<IsConst, IsReverse> {
    if (iter.listData != data.get()) {
        throw std::invalid_argument("L'iteratore appartiene a un'altra lista o è stato invalidato!");
    }
    
    bool wasShared = (data.use_count() > 1);
    size_t forwardIndex = 0;
    bool isEnd = (iter.current == nullptr);
    if (wasShared && !isEnd) {
        forwardIndex = IsReverse ? ((length() - 1) - iter.offset) : iter.offset;
    }
    
    ensureUnique();
    Node<T>* current = (wasShared && !isEnd) ? getNodeAt(forwardIndex) : unwrap(iter);
    
    if (!current) {
        if constexpr (IsReverse) {
            prependInternal(std::forward<U>(value));
            return BasicIterator<IsConst, IsReverse>(head(), data.get(), iter.offset);
        } else {
            appendInternal(std::forward<U>(value));
            return BasicIterator<IsConst, IsReverse>(tail(), data.get(), iter.offset);
        }
    }
    
    if constexpr (IsReverse) {
        if (current == tail()) {
            appendInternal(std::forward<U>(value));
            return BasicIterator<IsConst, IsReverse>(tail(), data.get(), iter.offset);
        } else {
            Node<T>* newNode = new Node<T>(std::forward<U>(value), current, current->getNext());
            length() += 1;
            return BasicIterator<IsConst, IsReverse>(newNode, data.get(), iter.offset);
        }
    } else {
        if (current == head()) {
            prependInternal(std::forward<U>(value));
            return BasicIterator<IsConst, IsReverse>(head(), data.get(), iter.offset);
        } else {
            Node<T>* newNode = new Node<T>(std::forward<U>(value), current->getPrevious(), current);
            length() += 1;
            return BasicIterator<IsConst, IsReverse>(newNode, data.get(), iter.offset);
        }
    }
}

// MARK: - Assignment

template<typename T>
inline LinkedList<T>& LinkedList<T>::operator=(LinkedList&& other) noexcept {
    if (this != &other) {
        data = std::exchange(other.data, std::make_shared<ListData>());
    }
    return *this;
}

// MARK: - Element Access & Subscripts

template<typename T>
template <bool IsConst, bool IsReverse>
inline const T& LinkedList<T>::operator[](BasicIterator<IsConst, IsReverse> iter) const {
    validateIterator(iter);
    return iter.current->value;
}

template<typename T>
template <bool IsConst, bool IsReverse>
inline T& LinkedList<T>::operator[](BasicIterator<IsConst, IsReverse> iter) {
    validateIterator(iter);
    if (data.use_count() == 1) {
        return const_cast<Node<T>*>(iter.current)->value;
    }
    ensureUnique();
    size_t index = IsReverse ? ((length() - 1) - iter.offset) : iter.offset;
    return getNodeAt(index)->value;
}

// MARK: - Modifiers: Clear

template<typename T>
inline void LinkedList<T>::clear() {
    if (getIsEmpty()) {
        return;
    }
    data = std::make_shared<ListData>();
}

// MARK: - Swift Hashable Support

template<typename T>
inline size_t LinkedList<T>::hashValue() const noexcept {
    size_t seed = length();
    for (const auto& item : *this) {
        seed ^= std::hash<T>{}(item) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
    }
    return seed;
}

// MARK: - Comparisons

template<typename T>
inline bool LinkedList<T>::operator==(const LinkedList& other) const {
    if (this == &other || data == other.data) {
        return true;
    }
    if (length() != other.length()) {
        return false;
    }
    return std::equal(begin(), end(), other.begin(), other.end());
}

template<typename T>
inline bool LinkedList<T>::operator<(const LinkedList& other) const requires std::totally_ordered<T> {
    if (this == &other || data == other.data) {
        return false;
    }
    auto it1 = begin();
    auto end1 = end();
    auto it2 = other.begin();
    auto end2 = other.end();
    while (it1 != end1 && it2 != end2) {
        if (*it1 < *it2) return true;
        if (*it2 < *it1) return false;
        ++it1;
        ++it2;
    }
    return (it1 == end1) && (it2 != end2);
}

template<typename T>
inline auto LinkedList<T>::operator<=>(const LinkedList& other) const {
    if (this == &other || data == other.data) {
        return std::strong_ordering::equal;
    }
    return std::lexicographical_compare_three_way(begin(), end(), other.begin(), other.end());
}

// MARK: - Index Navigation Helpers

template<typename T>
inline auto LinkedList<T>::indexBefore(ConstIterator iter) const -> ConstIterator {
    --iter;
    return iter;
}

template<typename T>
inline auto LinkedList<T>::indexAfter(ConstIterator iter) const -> ConstIterator {
    ++iter;
    return iter;
}

// MARK: - Modifiers: Append & Prepend

template<typename T>
inline void LinkedList<T>::append(const T& value) requires std::is_copy_constructible_v<T> {
    appendInternal(value);
}

template<typename T>
inline void LinkedList<T>::append(T&& value) {
    appendInternal(std::move(value));
}

template<typename T>
inline void LinkedList<T>::prepend(const T& value) requires std::is_copy_constructible_v<T> {
    prependInternal(value);
}

template<typename T>
inline void LinkedList<T>::prepend(T&& value) {
    prependInternal(std::move(value));
}

// MARK: - Modifiers: Extend

template<typename T>
inline void LinkedList<T>::extend(const LinkedList<T>& other) requires std::is_copy_constructible_v<T> {
    if (this == &other) {
        size_t count = length();
        auto it = begin();
        for (size_t i = 0; i < count; ++i, ++it) {
            append(*it);
        }
        return;
    }
    ensureUnique();
    for (const T& value : other) {
        append(value);
    }
}

template<typename T>
inline void LinkedList<T>::extend(LinkedList<T>&& other) {
    if (this == &other || !other.head()) {
        return;
    }
    ensureUnique();
    other.ensureUnique();
    
    if (!head()) {
        head() = other.head();
        tail() = other.tail();
        length() = other.length();
    } else {
        tail()->setNext(other.head());
        tail() = other.tail();
        length() += other.length();
    }
    
    other.head() = nullptr;
    other.tail() = nullptr;
    other.length() = 0;
}

template<typename T>
inline void LinkedList<T>::extend(std::initializer_list<T> init) {
    ensureUnique();
    for (const T& value : init) {
        append(value);
    }
}

template<typename T>
template <std::ranges::input_range R>
requires (std::convertible_to<std::ranges::range_reference_t<R>, T> && !std::same_as<std::remove_cvref_t<R>, LinkedList<T>>)
inline void LinkedList<T>::extend(R&& range) {
    ensureUnique();
    for (auto&& value : range) {
        append(std::forward<decltype(value)>(value));
    }
}

// MARK: - Modifiers: Insert

template<typename T>
inline void LinkedList<T>::insert(size_t index, const T& value) requires std::is_copy_constructible_v<T> {
    insertInternal(index, value);
}

template<typename T>
inline void LinkedList<T>::insert(size_t index, T&& value) {
    insertInternal(index, std::move(value));
}

template<typename T>
template <bool IsConst, bool IsReverse>
inline auto LinkedList<T>::insert(BasicIterator<IsConst, IsReverse> iter, const T& value) -> BasicIterator<IsConst, IsReverse> requires std::is_copy_constructible_v<T> {
    return insertAtIterator(iter, value);
}

template<typename T>
template <bool IsConst, bool IsReverse>
inline auto LinkedList<T>::insert(BasicIterator<IsConst, IsReverse> iter, T&& value) -> BasicIterator<IsConst, IsReverse> {
    return insertAtIterator(iter, std::move(value));
}

// MARK: - Modifiers: Pop & Remove

template<typename T>
inline T LinkedList<T>::popFirst() {
    ensureUnique();
    if (!head()) {
        throw std::out_of_range("La lista è vuota!");
    }
    return extractAndRemove(head());
}

template<typename T>
inline T LinkedList<T>::popLast() {
    ensureUnique();
    if (!tail()) {
        throw std::out_of_range("La lista è vuota!");
    }
    return extractAndRemove(tail());
}

template<typename T>
inline T LinkedList<T>::pop(size_t index) {
    ensureUnique();
    return extractAndRemove(getNodeAt(index));
}

template<typename T>
inline void LinkedList<T>::removeFirst() {
    if (!head()) throw std::out_of_range("La lista è vuota!");
    ensureUnique();
    removeInternal(head());
}

template<typename T>
inline void LinkedList<T>::removeLast() {
    if (!tail()) throw std::out_of_range("La lista è vuota!");
    ensureUnique();
    removeInternal(tail());
}

// MARK: - Modifiers: Erase

template<typename T>
template <bool IsConst, bool IsReverse>
inline auto LinkedList<T>::erase(BasicIterator<IsConst, IsReverse> iter) -> BasicIterator<IsConst, IsReverse> {
    validateIterator(iter);
    auto next = iter;
    ++next;
    return erase(iter, next);
}

template<typename T>
template <bool IsConst, bool IsReverse>
inline auto LinkedList<T>::erase(BasicIterator<IsConst, IsReverse> first, BasicIterator<IsConst, IsReverse> last) -> BasicIterator<IsConst, IsReverse> {
    if (first.listData != data.get() || last.listData != data.get()) {
        throw std::invalid_argument("Gli iteratori appartengono a un'altra lista o sono stati invalidati!");
    }
    if (first.offset > last.offset) {
        throw std::invalid_argument("Range non valido: first > last!");
    }
    if (first.offset > length() || last.offset > length()) {
        throw std::out_of_range("Indice fuori dai limiti della lista!");
    }
    if (first.offset == last.offset) {
        return last;
    }
    
    bool wasShared = (data.use_count() > 1);
    
    ensureUnique();
    
    Node<T>* curr = nullptr;
    Node<T>* endNode = nullptr;
    
    if constexpr (IsReverse) {
        if (wasShared) {
            size_t fwdStart = (length() - 1) - first.offset;
            curr = getNodeAt(fwdStart);
            endNode = (last.offset < length()) ? getNodeAt((length() - 1) - last.offset) : nullptr;
        } else {
            curr = unwrap(first);
            endNode = unwrap(last);
        }
        
        while (curr && curr != endNode) {
            Node<T>* prev = curr->getPrevious();
            removeInternal(curr);
            curr = prev;
        }
    } else {
        if (wasShared) {
            curr = getNodeAt(first.offset);
            endNode = (last.offset < length()) ? getNodeAt(last.offset) : nullptr;
        } else {
            curr = unwrap(first);
            endNode = unwrap(last);
        }
        
        while (curr && curr != endNode) {
            Node<T>* next = curr->getNext();
            removeInternal(curr);
            curr = next;
        }
    }
    return BasicIterator<IsConst, IsReverse>(endNode, data.get(), first.offset);
}

// MARK: - std::hash specialization for LinkedList
template <typename T>
struct std::hash<LinkedList<T>> {
    size_t operator()(const LinkedList<T>& list) const noexcept {
        return list.hashValue();
    }
};
