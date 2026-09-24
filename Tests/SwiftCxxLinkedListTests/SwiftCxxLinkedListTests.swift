//
//  SwiftCxxLinkedListTests.swift
//  SwiftCxxLinkedListTests
//
//  Created by Edoardo Frezzotti on 25/06/26.
//

import Testing
import CxxLinkedList
import CxxLinkedListTestSupport
import Foundation


@Suite(.serialized)
struct LinkedListUnitTests {
    
    @Test func testEmptyList() async throws {
        let list = IntLinkedList()
        #expect(list.count == 0)
    }
    
    @Test func testIndexInvalidationOnMutation() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        
        // Salviamo l'indice del valore "20" (offset 1)
        let indexOf20 = list.index(after: list.startIndex)
        #expect(list[indexOf20] == 20)
        
        // Mutiamo la lista inserendo un elemento prima del "20" (in testa)
        list.prepend(5)
        
        // Adesso la lista è: [5, 10, 20, 30]
        // Il vero indice (offset) del 20 adesso dovrebbe essere 2!
        // Ma il nostro `indexOf20` salvato ha ancora l'offset = 1.
        
        // Di conseguenza, se confrontiamo gli offset (che è quello che fa Collection), l'indice sembra non essere cambiato
        // e si trova in una posizione logica sfasata rispetto alla vera lista.
        // Se accediamo usando l'indice vecchio:
        let valueAtOldIndex = list[indexOf20]
        
        // Il valore restituito sarà ANCORA 20 (perché il puntatore al nodo è ancora valido in memoria C++ e punta a 20).
        // Tuttavia, questo viola le garanzie di Swift Collection, che prevede che l'indice sia invalidato dopo una mutazione.
        #expect(valueAtOldIndex == 20)
        
        // Se proviamo a iterare con il vecchio indice per trovare le distanze, i conti non tornano:
        let trueIndexOf20 = unsafe list.index(list.startIndex, offsetBy: 2) // Il nuovo indice corretto per il 20
        
        // Poiché entrambi puntano allo stesso nodo in memoria, per la relazione di equivalenza di Comparable:
        #expect(!(indexOf20 < trueIndexOf20))
        // Questo dimostra che il vecchio indice è desincronizzato rispetto all'offset reale (che ora è 2).
    }
    
    @Test func testAppendAndPop() async throws {
        var list = IntLinkedList()
        
        list.append(10)
        list.append(20)
        list.append(30)
        #expect(list.count == 3)
        
        let first = list.popFirst()
        #expect(first == 10)
        #expect(list.count == 2)
        
        let last = list.popLast()
        #expect(last == 30)
        #expect(list.count == 1)
    }
    
    @Test func testPrepend() async throws {
        var list = IntLinkedList()
        list.prepend(100)
        list.prepend(200)
        
        #expect(list.count == 2)
        #expect(list.popFirst() == 200)
        #expect(list.popFirst() == 100)
    }
    
    @Test func testCopyableAndEscapableConformances() async throws {
        func checkCopyable<T: Copyable>(_ value: T) {}
        func checkEscapable<T: Escapable>(_ value: T) {}
        
        let list = IntLinkedList()
        checkCopyable(list)
        checkEscapable(list)
        
        func checkCollection<C: Collection>(_ c: C) {}
        func checkBidirectional<C: BidirectionalCollection>(_ c: C) {}
        
        unsafe checkCollection(list)
        unsafe checkBidirectional(list)
        checkEscapable(list)
    }
    
    @Test func testDeepCopyAndAssignment() async throws {
        var original = IntLinkedList()
        original.append(1)
        original.append(2)
        
        // Deep copy via copy constructor
        var copy = original
        #expect(copy.count == 2)
        #expect(copy[0] == 1)
        #expect(copy[1] == 2)
        
        // Modifying original shouldn't affect copy
        original.append(3)
        #expect(original.count == 3)
        #expect(copy.count == 2)
        
        // Copy assignment operator
        var anotherList = IntLinkedList()
        anotherList.append(42)
        anotherList = copy
        #expect(anotherList.count == 2)
        #expect(anotherList[0] == 1)
        
        copy[0] = 99
        #expect(copy[0] == 99)
        #expect(anotherList[0] == 1) // Deep copy guarantees isolation
    }
    
    @Test func testSubscriptAndModification() async throws {
        var list = IntLinkedList()
        list.append(100)
        list.append(200)
        list.append(300)
        
        #expect(list[0] == 100)
        #expect(list[1] == 200)
        #expect(list[2] == 300)
        
        list[1] = 250
        #expect(list[1] == 250)
        #expect(list.count == 3)
    }
    
    @Test func testComplexInsertAndPop() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(30)
        
        // Insert at index 1
        list.insert(1, 20)
        #expect(list.count == 3)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
        #expect(list[2] == 30)
        
        // Insert at index 0 (prepend)
        list.insert(0, 5)
        #expect(list[0] == 5)
        
        // Insert at tail
        list.insert(4, 40)
        #expect(list.count == 5)
        #expect(list[4] == 40)
        
        // Pop from middle
        let popped = list.pop(2) // pop 20
        #expect(popped == 20)
        #expect(list.count == 4)
        #expect(list[0] == 5)
        #expect(list[1] == 10)
        #expect(list[2] == 30)
        #expect(list[3] == 40)
    }
    
    @Test func testStringLinkedList() async throws {
        var list = StringLinkedList()
        list.append(std.string("Swift"))
        list.append(std.string("C++"))
        list.append(std.string("Interop"))
        
        #expect(list.count == 3)
        #expect(list[0] == std.string("Swift"))
        #expect(list[1] == std.string("C++"))
        #expect(list[2] == std.string("Interop"))
        
        let popped = list.popFirst()
        #expect(popped == std.string("Swift"))
        #expect(list.count == 2)
    }
    
    /*
    @Test func testMoveOnlyAppend() async throws {
        var list = MoveOnlyLinkedList()
        list.append(consuming: MoveOnly(42))
        let finalList = consume list
        #expect(finalList.count == 1)
    }
    
    @Test func testMoveOnlyAppendTwice() async throws {
        var list = MoveOnlyLinkedList()
        list.append(consuming: MoveOnly(42))
        list.append(consuming: MoveOnly(84))
        let finalList = consume list
        #expect(finalList.count == 2)
    }
    
    @Test func testMoveOnlyConsume() async throws {
        var list = MoveOnlyLinkedList()
        list.append(consuming: MoveOnly(42))
        let movedList = consume list
        #expect(movedList.count == 1)
    }
    
    @Test func testMoveOnlyPopOne() async throws {
        var list = MoveOnlyLinkedList()
        list.append(consuming: MoveOnly(42))
        let first = list.popFirst()
        #expect(first.value == 42)
        let finalList = consume list
        #expect(finalList.count == 0)
    }
    
    @Test func testMoveOnlyPop() async throws {
        var list = MoveOnlyLinkedList()
        list.append(consuming: MoveOnly(42))
        list.append(consuming: MoveOnly(84))
        let first = list.popFirst()
        #expect(first.value == 42)
        let finalList = consume list
        #expect(finalList.count == 1)
    }
    */
    
    @Test func testLifecycleTracking() async throws {
        LifecycleTracker.reset()
        
        do {
            var list = LifecycleLinkedList()
            list.append(LifecycleTracker(10))
            list.append(LifecycleTracker(20))
            #expect(list.count == 2)
            
            // Check that elements were constructed and some moved
            #expect(LifecycleTracker.getConstructCount() > 0)
            #expect(LifecycleTracker.getDestructCount() > 0)
            
            let initialDestruct = LifecycleTracker.getDestructCount()
            let popped = list.popFirst()
            #expect(popped.value == 10)
            #expect(list.count == 1)
            #expect(LifecycleTracker.getDestructCount() > initialDestruct)
        }
        
        // After the list is out of scope, everything must be cleared/destructed.
        #expect(LifecycleTracker.getConstructCount() == LifecycleTracker.getDestructCount())
    }
    
    @Test func testClearAndReuse() async throws {
        var list = IntLinkedList()
        list.append(1)
        list.append(2)
        list.clear()
        #expect(list.count == 0)
        
        list.append(10)
        list.append(20)
        #expect(list.count == 2)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
    }
    
    @Test func testStringLinkedListComplex() async throws {
        var list = StringLinkedList()
        list.prepend(std.string("Start"))
        list.append(std.string("End"))
        list.insert(1, std.string("Middle"))
        
        #expect(list.count == 3)
        #expect(list[0] == std.string("Start"))
        #expect(list[1] == std.string("Middle"))
        #expect(list[2] == std.string("End"))
        
        let poppedMiddle = list.pop(1)
        #expect(poppedMiddle == std.string("Middle"))
        #expect(list.count == 2)
    }
    
    // MARK: - Complex Computation Test 1: Polynomial Multiplication using String and Int Linked Lists
    @Test func testPolynomialMultiplication() async throws {
        // Polynomial A: 3x^2 - 2x + 5
        var polyA = StringLinkedList()
        polyA.append(std.string("3x^2"))
        polyA.append(std.string("-2x"))
        polyA.append(std.string("5"))
        
        // Polynomial B: 2x - 1
        var polyB = StringLinkedList()
        polyB.append(std.string("2x"))
        polyB.append(std.string("-1"))
        
        // Multiply polyA and polyB
        let result = multiplyPolynomials(polyA, polyB)
        
        // Expected product: 6x^3 - 7x^2 + 12x - 5
        #expect(result.count == 4)
        #expect(result[0] == std.string("6x^3"))
        #expect(result[1] == std.string("-7x^2"))
        #expect(result[2] == std.string("+12x"))
        #expect(result[3] == std.string("-5"))
    }
    
    private func multiplyPolynomials(_ polyA: StringLinkedList, _ polyB: StringLinkedList) -> StringLinkedList {
        var termsA: [(coeff: Int, exp: Int)] = []
        for poly in polyA {
            let str = String(poly)
            termsA.append(parseTerm(str))
        }
        
        var termsB: [(coeff: Int, exp: Int)] = []
        for poly in polyB {
            let str = String(poly)
            termsB.append(parseTerm(str))
        }
        
        var coefficients = IntLinkedList()
        
        for tA in termsA {
            for tB in termsB {
                let coeff = tA.coeff * tB.coeff
                let exp = tA.exp + tB.exp
                
                if coeff == 0 { continue }
                
                while coefficients.count <= exp {
                    coefficients.append(0)
                }
                
                let currentVal = coefficients[exp]
                coefficients[exp] = currentVal + Int32(coeff)
            }
        }
        
        var resultPoly = StringLinkedList()
        var isLeading = true
        
        if coefficients.count > 0 {
            for i in stride(from: coefficients.count - 1, through: 0, by: -1) {
                let coeff = Int(coefficients[i])
                if coeff != 0 {
                    let formatted = formatTerm(coeff: coeff, exp: i, isLeading: isLeading)
                    if !formatted.isEmpty {
                        resultPoly.append(std.string(formatted))
                        isLeading = false
                    }
                }
            }
        }
        
        return resultPoly
    }
    
    private func parseTerm(_ term: String) -> (coeff: Int, exp: Int) {
        let clean = term.replacingOccurrences(of: " ", with: "")
        guard !clean.isEmpty else { return (0, 0) }
        
        if let xRange = clean.range(of: "x") {
            let coeffStr = String(clean[..<xRange.lowerBound])
            let coeff: Int = if coeffStr.isEmpty || coeffStr == "+" {
                1
            } else if coeffStr == "-" {
                -1
            } else {
                Int(coeffStr) ?? 0
            }
            
            let postX = clean[xRange.upperBound...]
            if postX.hasPrefix("^") {
                let expStr = String(postX.dropFirst())
                let exp = Int(expStr) ?? 0
                return (coeff, exp)
            } else {
                return (coeff, 1)
            }
        } else {
            let coeff = Int(clean) ?? 0
            return (coeff, 0)
        }
    }
    
    private func formatTerm(coeff: Int, exp: Int, isLeading: Bool) -> String {
        if coeff == 0 { return "" }
        let sign: String
        if coeff > 0 {
            sign = isLeading ? "" : "+"
        } else {
            sign = "-"
        }
        let absCoeff = abs(coeff)
        let coeffStr: String
        if absCoeff == 1 && exp > 0 {
            coeffStr = ""
        } else {
            coeffStr = "\(absCoeff)"
        }
        let expStr: String
        if exp == 0 {
            expStr = ""
        } else if exp == 1 {
            expStr = "x"
        } else {
            expStr = "x^\(exp)"
        }
        return "\(sign)\(coeffStr)\(expStr)"
    }
    
    // MARK: - Complex Computation Test 2: DNA Sequence Processor using StringLinkedList
    @Test func testDnaSequenceProcessor() async throws {
        // DNA Sequence: 5'-ATG GCA TCG GTA CTA GCG-3'
        var dna = StringLinkedList()
        dna.append(std.string("ATG"))
        dna.append(std.string("GCA"))
        dna.append(std.string("TCG"))
        dna.append(std.string("GTA"))
        dna.append(std.string("CTA"))
        dna.append(std.string("GCG"))
        
        // 1. Transcription to RNA: replace T with U
        let rna = transcribe(dna)
        #expect(rna.count == 6)
        #expect(rna[0] == std.string("AUG"))
        #expect(rna[2] == std.string("UCG"))
        
        // 2. Translation to Amino Acids (Protein)
        let protein = translate(rna)
        #expect(protein.count == 6)
        #expect(protein[0] == std.string("Met"))
        #expect(protein[1] == std.string("Ala"))
        #expect(protein[2] == std.string("Ser"))
        #expect(protein[3] == std.string("Val"))
        #expect(protein[4] == std.string("Leu"))
        #expect(protein[5] == std.string("Ala"))
        
        // 3. Mutate DNA: insert a STOP codon (TAG -> RNA: UAG) at index 3
        var mutatedDna = dna
        mutatedDna.insert(3, std.string("TAG"))
        #expect(mutatedDna.count == 7)
        #expect(mutatedDna[3] == std.string("TAG"))
        
        let mutatedRna = transcribe(mutatedDna)
        #expect(mutatedRna[3] == std.string("UAG"))
        
        let truncatedProtein = translate(mutatedRna)
        // Translation should stop at the STOP codon
        #expect(truncatedProtein.count == 3)
        #expect(truncatedProtein[0] == std.string("Met"))
        #expect(truncatedProtein[1] == std.string("Ala"))
        #expect(truncatedProtein[2] == std.string("Ser"))
        
        // 4. Reverse Complement of original DNA
        // Original: 5'-ATG GCA TCG GTA CTA GCG-3'
        // Reverse Complement: 5'-CGC TAG TAC CGA TGC CAT-3'
        let revComp = reverseComplementDna(dna)
        #expect(revComp.count == 6)
        #expect(revComp[0] == std.string("CGC"))
        #expect(revComp[1] == std.string("TAG"))
        #expect(revComp[2] == std.string("TAC"))
        #expect(revComp[3] == std.string("CGA"))
        #expect(revComp[4] == std.string("TGC"))
        #expect(revComp[5] == std.string("CAT"))
    }
    
    private func transcribe(_ dna: StringLinkedList) -> StringLinkedList {
        var rna = StringLinkedList()
        for prot in dna {
            let dnaCodon = String(prot)
            let rnaCodon = dnaCodon.replacingOccurrences(of: "T", with: "U")
            rna.append(std.string(rnaCodon))
        }
        return rna
    }
    
    private func translate(_ rna: StringLinkedList) -> StringLinkedList {
        let codonTable: [String: String] = [
            "AUG": "Met",
            "GCA": "Ala",
            "UCG": "Ser",
            "GUA": "Val",
            "CUA": "Leu",
            "GCG": "Ala",
            "UAG": "Stop",
            "UAA": "Stop",
            "UGA": "Stop"
        ]
        
        var protein = StringLinkedList()
        for prot in rna {
            let rnaCodon = String(prot)
            let aa = codonTable[rnaCodon] ?? "Unknown"
            if aa == "Stop" {
                break
            }
            protein.append(std.string(aa))
        }
        return protein
    }
    
    private func reverseComplementDna(_ dna: StringLinkedList) -> StringLinkedList {
        var revComp = StringLinkedList()
        let complement: [Character: Character] = [
            "A": "T",
            "T": "A",
            "C": "G",
            "G": "C"
        ]
        
        if dna.count > 0 {
            for i in stride(from: dna.count - 1, through: 0, by: -1) {
                let codon = String(dna[i])
                let revCompCodon = String(codon.reversed().map { complement[$0] ?? $0 })
                revComp.append(std.string(revCompCodon))
            }
        }
        
        return revComp
    }
    
    // MARK: - Sequence Conformance Tests
    @Test func testIntSequenceConformance() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        
        var values: [Int32] = []
        for x in list {
            values.append(x)
        }
        #expect(values == [10, 20, 30])
        
        let mapped = unsafe list.map { $0 * 2 }
        #expect(mapped == [20, 40, 60])
        
        let array = Array(list)
        #expect(array == [10, 20, 30])
    }
    
    @Test func testStringSequenceConformance() async throws {
        var list = StringLinkedList()
        list.append(std.string("A"))
        list.append(std.string("B"))
        
        let array = unsafe list.map { String($0) }
        #expect(array == ["A", "B"])
    }
    
    // MARK: - Safe Interop Wrappers Tests
    @Test func testSafeInteropWrappers() async throws {
        let sourceArray: [Int32] = [10, 20, 30, 40]
        let list: IntLinkedList = sourceArray.withUnsafeBufferPointer { ptr in
            let span = unsafe Span(_unsafeElements: ptr)
            return makeListFromSpan(span)
        }
        #expect(list.count == 4)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
        #expect(list[2] == 30)
        #expect(list[3] == 40)
        
        let sum: Int32 = sourceArray.withUnsafeBufferPointer { ptr in
            let span = unsafe Span(_unsafeElements: ptr)
            return sumSpan(span)
        }
        #expect(sum == 100)
    }
    
    // MARK: - Collection & BidirectionalCollection Tests
    
    @Test func testCollectionFirstAndLast() async throws {
        let emptyList = IntLinkedList()
        #expect(emptyList.isEmpty)
        #expect(unsafe emptyList.first == nil)
        #expect(unsafe emptyList.last == nil)
        
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        #expect(!list.isEmpty)
        #expect(unsafe list.first == 10)
        #expect(unsafe list.last == 30)
    }
    
    @Test func testBidirectionalReversal() async throws {
        var list = IntLinkedList()
        list.append(1)
        list.append(2)
        list.append(3)
        list.append(4)
        list.append(5)
        
        let reversedElements = unsafe Array(list.reversed())
        #expect(reversedElements == [5, 4, 3, 2, 1])
    }
    
    @Test func testCollectionPrefixAndSuffix() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        list.append(40)
        list.append(50)
        
        let prefixThree = unsafe Array(list.prefix(3))
        #expect(prefixThree == [10, 20, 30])
        
        let suffixTwo = unsafe Array(list.suffix(2))
        #expect(suffixTwo == [40, 50])
    }
    
    @Test func testCollectionDropFirstAndDropLast() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        list.append(40)
        list.append(50)
        
        let dropFirstTwo = unsafe Array(list.dropFirst(2))
        #expect(dropFirstTwo == [30, 40, 50])
        
        let dropLastTwo = unsafe Array(list.dropLast(2))
        #expect(dropLastTwo == [10, 20, 30])
    }
    
    @Test func testCollectionHigherOrderAlgorithms() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        list.append(40)
        list.append(50)
        
        let doubled = unsafe list.map { $0 * 2 }
        #expect(doubled == [20, 40, 60, 80, 100])
        
        let filtered = Array(list).filter { $0 > 25 }
        #expect(filtered == [30, 40, 50])
        
        let totalSum = list.reduce(0, +)
        #expect(totalSum == 150)
    }
    
    @Test func testCollectionRangeSlicing() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        list.append(40)
        list.append(50)
        
        // In Swift, le collezioni con Index != Int (come LinkedList o String)
        // non si tagliano con range di interi, ma con i loro Indici, oppure con metodi idiomatici:
        let middleSlice = unsafe list.dropFirst(1).prefix(3)
        #expect(Array(middleSlice) == [20, 30, 40])
        
        let prefixSlice = unsafe list.prefix(3)
        #expect(Array(prefixSlice) == [10, 20, 30])
        
        let suffixSlice = unsafe list.dropFirst(2)
        #expect(Array(suffixSlice) == [30, 40, 50])
        
        // Se si vuole usare il subscript, si usano gli indici reali (costo lineare O(N) esplicito)
        let startIndex = unsafe list.index(list.startIndex, offsetBy: 1)
        let endIndex = unsafe list.index(list.startIndex, offsetBy: 4)
        let explicitSlice = unsafe list[startIndex..<endIndex]
        #expect(Array(explicitSlice) == [20, 30, 40])
    }
    
    @Test func testBidirectionalBackwardsSearch() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(25)
        list.append(30)
        list.append(45)
        list.append(50)
        
        // last(where:) scans backwards directly
        let lastEven = unsafe list.last(where: { $0 % 2 == 0 })
        #expect(lastEven == 50)
        
        let lastDivisibleByFive = unsafe list.last(where: { $0 < 40 && $0 % 5 == 0 })
        #expect(lastDivisibleByFive == 30)
        
        // lastIndex(of:) is exclusive to BidirectionalCollection
        let lastIndex = unsafe list.lastIndex(of: 30)
        let expectedIndex = unsafe list.index(list.startIndex, offsetBy: 2)
        #expect(lastIndex == expectedIndex)
    }
    
    @Test func testBidirectionalPalindromeAlgorithm() async throws {
        func isPalindrome<C: BidirectionalCollection>(_ collection: C) -> Bool where C.Element: Equatable {
            return Array(collection) == Array(collection.reversed())
        }
        
        let palindromeList = IntLinkedList([1, 2, 3, 2, 1])
        let isP = unsafe isPalindrome(palindromeList)
        #expect(isP == true)
        
        let nonPalindromeList = IntLinkedList([1, 2, 3])
        let isNonP = unsafe isPalindrome(nonPalindromeList)
        #expect(isNonP == false)
    }
    
    @Test func testCollectionSorting() async throws {
        var list = IntLinkedList()
        list.append(42)
        list.append(7)
        list.append(19)
        list.append(7)
        list.append(-3)
        list.append(100)
        
        // 1. Ascending sort using default Comparable conformance
        let ascending = list.sorted()
        #expect(ascending == [-3, 7, 7, 19, 42, 100])
        
        // 2. Descending sort using custom predicate
        let descending = list.sorted(by: { $0 > $1 })
        #expect(descending == [100, 42, 19, 7, 7, -3])
    }
    
    @Test func testConvenienceInitializersAndMutation() async throws {
        // Init from Swift sequence
        var list = IntLinkedList([10, 20, 30, 40, 50])
        #expect(list.count == 5)
        #expect(list[0] == 10)
        #expect(list[4] == 50)
        
        // MutableCollection in-place subscript modification
        list[2] = 99
        #expect(list[2] == 99)
        #expect(Array(list) == [10, 20, 99, 40, 50])
        
        // StringLinkedList from native Swift strings
        let stringList = StringLinkedList(strings: ["Swift", "C++", "Interop"])
        #expect(stringList.count == 3)
        #expect(stringList[0] == std.string("Swift"))
        #expect(stringList[1] == std.string("C++"))
        #expect(stringList[2] == std.string("Interop"))
    }

    // MARK: - Bidirectional Algorithms & Dangling Pointer
    
    @Test func testBidirectionalAlgorithms() async throws {
        let list = IntLinkedList([10, 20, 30, 40, 50])
        
        // 1. suffix works via BidirectionalCollection
        let lastTwo = unsafe Array(list.suffix(2))
        #expect(lastTwo == [40, 50])
        
        // 2. reversed() works in O(1) by wrapping the collection
        let reversedList = unsafe list.reversed()
        let reversedArray = Array(reversedList)
        #expect(reversedArray == [50, 40, 30, 20, 10])
        
        // 3. index(offsetBy) should work by doing linear traversal (O(n))
        let middleIndex = unsafe list.index(list.startIndex, offsetBy: 2)
        #expect(list[middleIndex] == 30)
    }

    @Test func testDecrementAtBeginStaysAtBegin() async throws {
        let list = IntLinkedList([10, 20, 30])
        let start = list.startIndex
        let decremented = list.index(before: start)
        #expect(decremented == start)
        #expect(list[decremented] == 10)
    }

    @Test func testDanglingPointerAfterClear() async throws {
        // Test per documentare l'Undefined Behavior (che in Swift sfocia solitamente in un segmentation fault).
        // WARNING: se de-commenti l'ultima istruzione e avvii il test runner, il processo crasherà!
        // Questo prova l'assenza di memory safety dell'indice una volta che la lista dealloca i nodi C++.
        var list = IntLinkedList([100, 200, 300])
        
        let index = list.index(after: list.startIndex)
        let valueBefore = list[index]
        #expect(valueBefore == 200)
        
        // Chiamiamo clear, deallocando fisicamente i nodi in C++
        list.clear()
        
        // Ora 'index' contiene un raw pointer a una memoria distrutta.
        // let valueAfter = list[index] // CRASH: EXC_BAD_ACCESS
        
        // Per ora ci limitiamo a testare che la lista sia vuota
        #expect(list.count == 0)
    }
    
    // MARK: - Single Element Edge Cases
    
    @Test func testSingleElementRemoveFirst() async throws {
        var list = IntLinkedList()
        list.append(42)
        #expect(list.count == 1)
        
        list.removeFirst()
        #expect(list.count == 0)
        #expect(list.isEmpty)
    }
    
    @Test func testSingleElementRemoveLast() async throws {
        var list = IntLinkedList()
        list.append(42)
        
        list.removeLast()
        #expect(list.count == 0)
        #expect(list.isEmpty)
    }
    
    @Test func testSingleElementPopFirst() async throws {
        var list = IntLinkedList()
        list.append(99)
        
        let popped = list.popFirst()
        #expect(popped == 99)
        #expect(list.count == 0)
    }
    
    @Test func testSingleElementPopLast() async throws {
        var list = IntLinkedList()
        list.append(99)
        
        let popped = list.popLast()
        #expect(popped == 99)
        #expect(list.count == 0)
    }
    
    @Test func testSingleElementSubscript() async throws {
        var list = IntLinkedList()
        list.append(7)
        
        #expect(list[0] == 7)
        list[0] = 42
        #expect(list[0] == 42)
        #expect(list.count == 1)
    }
    
    @Test func testSingleElementInsertAtZero() async throws {
        var list = IntLinkedList()
        list.append(20)
        
        list.insert(0, 10)
        #expect(list.count == 2)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
    }
    
    @Test func testSingleElementInsertAtEnd() async throws {
        var list = IntLinkedList()
        list.append(10)
        
        list.insert(1, 20)
        #expect(list.count == 2)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
    }
    
    // MARK: - Extend Edge Cases
    
    @Test func testExtendWithEmptyList() async throws {
        var list = IntLinkedList()
        list.append(1)
        list.append(2)
        
        let empty = IntLinkedList()
        list.extend(empty)
        #expect(list.count == 2)
        #expect(list[0] == 1)
        #expect(list[1] == 2)
    }
    
    @Test func testExtendEmptyListWithNonEmpty() async throws {
        var empty = IntLinkedList()
        
        var source = IntLinkedList()
        source.append(10)
        source.append(20)
        
        empty.extend(source)
        #expect(empty.count == 2)
        #expect(empty[0] == 10)
        #expect(empty[1] == 20)
    }
    
    @Test func testExtendWithSelf() async throws {
        var list = IntLinkedList()
        list.append(1)
        list.append(2)
        list.append(3)
        
        // extend(self) should duplicate elements (using a copy snapshot to respect Swift's exclusivity)
        let copy = list
        list.extend(copy)
        #expect(list.count == 6)
        #expect(list[0] == 1)
        #expect(list[1] == 2)
        #expect(list[2] == 3)
        #expect(list[3] == 1)
        #expect(list[4] == 2)
        #expect(list[5] == 3)
    }
    
    @Test func testExtendBothEmpty() async throws {
        var a = IntLinkedList()
        let b = IntLinkedList()
        
        a.extend(b)
        #expect(a.count == 0)
        #expect(a.isEmpty)
    }
    
    // MARK: - COW (Copy-on-Write) Detailed Tests
    
    @Test func testCOWDoesNotCopyOnRead() async throws {
        LifecycleTracker.reset()
        
        var original = LifecycleLinkedList()
        original.append(LifecycleTracker(10))
        original.append(LifecycleTracker(20))
        
        let copyCountBefore = LifecycleTracker.getCopyCount()
        
        // Read-only access should NOT trigger a deep copy
        let copy = original
        _ = copy.count
        _ = copy.isEmpty
        
        let copyCountAfter = LifecycleTracker.getCopyCount()
        // No additional copies should have occurred from COW
        #expect(copyCountAfter == copyCountBefore)
    }
    
    @Test func testCOWIsolationOnMutation() async throws {
        var original = IntLinkedList()
        original.append(1)
        original.append(2)
        original.append(3)
        
        // Create a COW copy
        var copy = original
        
        // Mutate the copy
        copy.append(4)
        copy[0] = 99
        
        // Original should be unchanged
        #expect(original.count == 3)
        #expect(original[0] == 1)
        #expect(original[1] == 2)
        #expect(original[2] == 3)
        
        // Copy should reflect mutations
        #expect(copy.count == 4)
        #expect(copy[0] == 99)
        #expect(copy[3] == 4)
    }
    
    @Test func testCOWMultipleCopies() async throws {
        var a = IntLinkedList()
        a.append(1)
        a.append(2)
        
        let b = a
        var c = a
        
        // Mutate c
        c.append(3)
        
        // a and b should be identical and unchanged
        #expect(a.count == 2)
        #expect(b.count == 2)
        #expect(a[0] == b[0])
        #expect(a[1] == b[1])
        
        // c should have the extra element
        #expect(c.count == 3)
        #expect(c[2] == 3)
    }
    
    @Test func testCOWWithRemoveOperations() async throws {
        var original = IntLinkedList([10, 20, 30, 40])
        let snapshot = original
        
        // Mutate original via removal
        original.removeFirst()
        original.removeLast()
        
        // Snapshot should be unchanged
        #expect(snapshot.count == 4)
        #expect(snapshot[0] == 10)
        #expect(snapshot[3] == 40)
        
        // Original should reflect removals
        #expect(original.count == 2)
        #expect(original[0] == 20)
        #expect(original[1] == 30)
    }
    
    // MARK: - Contains, firstIndex, lastIndex with Duplicates
    
    @Test func testContainsAndSearch() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        list.append(20)
        list.append(40)
        
        #expect(list.contains(20))
        #expect(list.contains(10))
        #expect(list.contains(40))
        #expect(!list.contains(99))
        #expect(!list.contains(0))
    }
    
    @Test func testFirstIndexAndLastIndexWithDuplicates() async throws {
        var list = IntLinkedList()
        list.append(10)
        list.append(20)
        list.append(30)
        list.append(20)
        list.append(40)
        
        let first20 = unsafe list.firstIndex(of: 20)
        let last20 = unsafe list.lastIndex(of: 20)
        
        #expect(first20 != nil)
        #expect(last20 != nil)
        #expect(first20 != last20) // They should be different indices
        #expect(first20! < last20!) // First occurrence comes before last
        
        // Verify the values
        #expect(list[first20!] == 20)
        #expect(list[last20!] == 20)
        
        // firstIndex of non-existent element
        #expect(unsafe list.firstIndex(of: 99) == nil)
    }
    
    // MARK: - ExpressibleByArrayLiteral Tests
    
    @Test func testIntArrayLiteral() async throws {
        let list: IntLinkedList = [10, 20, 30]
        #expect(list.count == 3)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
        #expect(list[2] == 30)
    }
    
    @Test func testEmptyArrayLiteral() async throws {
        let list: IntLinkedList = []
        #expect(list.count == 0)
        #expect(list.isEmpty)
    }
    
    @Test func testStringArrayLiteral() async throws {
        let list: StringLinkedList = ["A", "B", "C"]
        #expect(list.count == 3)
        #expect(list[0] == std.string("A"))
        #expect(list[2] == std.string("C"))
    }
    
    // MARK: - CustomStringConvertible Tests
    
    @Test func testIntListDescription() async throws {
        var list = IntLinkedList()
        list.append(1)
        list.append(2)
        list.append(3)
        
        let desc = String(describing: list)
        #expect(desc == "[1, 2, 3]")
    }
    
    @Test func testEmptyListDescription() async throws {
        let list = IntLinkedList()
        let desc = String(describing: list)
        #expect(desc == "[]")
    }
    
    @Test func testStringListDescription() async throws {
        var list = StringLinkedList()
        list.append(std.string("Hello"))
        list.append(std.string("World"))
        
        let desc = String(describing: list)
        #expect(desc == "[Hello, World]")
    }
    
    // MARK: - Equatable Tests
    
    @Test func testIntListEquality() async throws {
        var a = IntLinkedList()
        a.append(1)
        a.append(2)
        a.append(3)
        
        var b = IntLinkedList()
        b.append(1)
        b.append(2)
        b.append(3)
        
        #expect(Bool(a == b))
    }
    
    @Test func testIntListInequality() async throws {
        var a = IntLinkedList()
        a.append(1)
        a.append(2)
        
        var b = IntLinkedList()
        b.append(1)
        b.append(3)
        
        #expect(Bool(a != b))
    }
    
    @Test func testIntListInequalityDifferentLength() async throws {
        var a = IntLinkedList()
        a.append(1)
        a.append(2)
        
        var b = IntLinkedList()
        b.append(1)
        b.append(2)
        b.append(3)
        
        #expect(Bool(a != b))
    }
    
    @Test func testEmptyListEquality() async throws {
        let a = IntLinkedList()
        let b = IntLinkedList()
        #expect(Bool(a == b))
    }
    
    @Test func testStringListEquality() async throws {
        var a = StringLinkedList()
        a.append(std.string("X"))
        a.append(std.string("Y"))
        
        var b = StringLinkedList()
        b.append(std.string("X"))
        b.append(std.string("Y"))
        
        #expect(Bool(a == b))
    }
    
    // MARK: - Comparable Tests
    
    @Test func testComparableConformance() async throws {
        func checkComparable<C: Comparable>(_ value: C) {}
        checkComparable(IntLinkedList())
        checkComparable(StringLinkedList())
    }
    
    @Test func testIntListComparison() async throws {
        var a = IntLinkedList()
        a.append(1)
        a.append(2)
        a.append(3)
        
        var b = IntLinkedList()
        b.append(1)
        b.append(2)
        b.append(3)
        
        var c = IntLinkedList()
        c.append(1)
        c.append(2)
        c.append(4)
        
        // Equal lists
        #expect(Bool(!(a < b)))
        #expect(Bool(!(b < a)))
        #expect(Bool(a <= b))
        #expect(Bool(a >= b))
        
        // Less than / Greater than
        #expect(Bool(a < c))
        #expect(Bool(a <= c))
        #expect(Bool(c > a))
        #expect(Bool(c >= a))
        #expect(Bool(!(c < a)))
    }
    
    @Test func testIntListComparisonDifferentLength() async throws {
        var shortList = IntLinkedList()
        shortList.append(1)
        shortList.append(2)
        
        var longList = IntLinkedList()
        longList.append(1)
        longList.append(2)
        longList.append(3)
        
        #expect(Bool(shortList < longList))
        #expect(Bool(shortList <= longList))
        #expect(Bool(longList > shortList))
        #expect(Bool(longList >= shortList))
        
        let empty = IntLinkedList()
        #expect(Bool(empty < shortList))
        #expect(Bool(shortList > empty))
    }
    
    @Test func testComparableSorting() async throws {
        var l1 = IntLinkedList()
        l1.append(3)
        l1.append(1)
        
        var l2 = IntLinkedList()
        l2.append(1)
        l2.append(2)
        l2.append(3)
        
        var l3 = IntLinkedList()
        l3.append(1)
        l3.append(2)
        
        let l4 = IntLinkedList()
        
        let array = [l1, l2, l3, l4]
        let sorted = array.sorted()
        
        #expect(Bool(sorted[0] == l4))
        #expect(Bool(sorted[1] == l3))
        #expect(Bool(sorted[2] == l2))
        #expect(Bool(sorted[3] == l1))
    }
    
    @Test func testStringListComparison() async throws {
        var s1 = StringLinkedList()
        s1.append(std.string("Apple"))
        s1.append(std.string("Banana"))
        
        var s2 = StringLinkedList()
        s2.append(std.string("Apple"))
        s2.append(std.string("Cherry"))
        
        #expect(Bool(s1 < s2))
        #expect(Bool(s1 <= s2))
        #expect(Bool(s2 > s1))
        #expect(Bool(s2 >= s1))
    }
    
    // MARK: - Testing Hashable
    
    @Test func testHashableConsistency() async throws {
        var a = IntLinkedList()
        a.append(1)
        a.append(2)
        a.append(3)
        
        var b = IntLinkedList()
        b.append(1)
        b.append(2)
        b.append(3)
        
        // Equal values must produce equal hashes
        #expect(a.hashValue == b.hashValue)
        
        // Test StringLinkedList is also Hashable via C++ bridging!
        var sa = StringLinkedList()
        sa.append(std.string("Hello"))
        sa.append(std.string("World"))
        
        var sb = StringLinkedList()
        sb.append(std.string("Hello"))
        sb.append(std.string("World"))
        
        #expect(sa.hashValue == sb.hashValue)
        let stringSet: Set<StringLinkedList> = [sa, sb]
        #expect(stringSet.count == 1)
    }
    
    @Test func testHashableAsSetElement() async throws {
        var list1 = IntLinkedList()
        list1.append(1)
        list1.append(2)
        
        var list2 = IntLinkedList()
        list2.append(1)
        list2.append(2)
        
        var list3 = IntLinkedList()
        list3.append(3)
        list3.append(4)
        
        let set: Set<IntLinkedList> = [list1, list2, list3]
        // list1 and list2 are equal, so the set should have 2 elements
        #expect(set.count == 2)
    }
    
    @Test func testHashableAsDictionaryKey() async throws {
        var key = IntLinkedList()
        key.append(1)
        key.append(2)
        
        var dict: [IntLinkedList: String] = [:]
        dict[key] = "found"
        
        // Same content, different instance
        var lookupKey = IntLinkedList()
        lookupKey.append(1)
        lookupKey.append(2)
        
        #expect(dict[lookupKey] == "found")
    }
    
    // MARK: - RemoveFirst / RemoveLast Tests
    
    @Test func testRemoveFirstMultiple() async throws {
        var list = IntLinkedList([10, 20, 30, 40])
        
        list.removeFirst()
        #expect(list.count == 3)
        #expect(list[0] == 20)
        
        list.removeFirst()
        #expect(list.count == 2)
        #expect(list[0] == 30)
    }
    
    @Test func testRemoveLastMultiple() async throws {
        var list = IntLinkedList([10, 20, 30, 40])
        
        list.removeLast()
        #expect(list.count == 3)
        #expect(list[2] == 30)
        
        list.removeLast()
        #expect(list.count == 2)
        #expect(list[1] == 20)
    }
    
    @Test func testRemoveAlternatingFirstLast() async throws {
        var list = IntLinkedList([1, 2, 3, 4, 5])
        
        list.removeFirst() // [2, 3, 4, 5]
        list.removeLast()  // [2, 3, 4]
        list.removeFirst() // [3, 4]
        list.removeLast()  // [3]
        
        #expect(list.count == 1)
        #expect(list[0] == 3)
    }
    
    // MARK: - Clear on Empty List
    
    @Test func testClearEmptyList() async throws {
        var list = IntLinkedList()
        list.clear()
        #expect(list.count == 0)
        #expect(list.isEmpty)
        
        // Should still work after clearing
        list.append(42)
        #expect(list.count == 1)
        #expect(list[0] == 42)
    }
    
    // MARK: - Multiple Sequential Operations Stress Test
    
    @Test func testSequentialOperationsStress() async throws {
        var list = IntLinkedList()
        
        // Build up
        for i: Int32 in 0..<100 {
            list.append(i)
        }
        #expect(list.count == 100)
        #expect(list[0] == 0)
        #expect(list[99] == 99)
        
        // Remove from both ends
        for _ in 0..<25 {
            list.removeFirst()
        }
        for _ in 0..<25 {
            list.removeLast()
        }
        #expect(list.count == 50)
        #expect(list[0] == 25)
        #expect(list[49] == 74)
        
        // Insert at various positions
        list.insert(0, -1)
        list.insert(list.count, 999)
        list.insert(26, 500)
        #expect(list.count == 53)
        #expect(list[0] == -1)
        #expect(list[52] == 999)
        #expect(list[26] == 500)
        
        // Clear and rebuild
        list.clear()
        #expect(list.isEmpty)
        
        list.append(1)
        list.append(2)
        #expect(list.count == 2)
    }
    
    // MARK: - Lifecycle Tracking with COW
    
    @Test func testLifecycleTrackingWithCOW() async throws {
        LifecycleTracker.reset()
        
        do {
            var original = LifecycleLinkedList()
            original.append(LifecycleTracker(1))
            original.append(LifecycleTracker(2))
            original.append(LifecycleTracker(3))
            
            // COW copy (should NOT deep copy yet)
            var copy = original
            _ = copy.count // read-only, no copy
            
            // Mutate copy → triggers deep copy via ensureUnique
            copy.append(LifecycleTracker(4))
            
            #expect(original.count == 3)
            #expect(copy.count == 4)
        }
        
        // After both are out of scope, constructs == destructs (no leaks)
        #expect(LifecycleTracker.getConstructCount() == LifecycleTracker.getDestructCount())
    }
    
    // MARK: - RemoveAt Tests
    
    @Test func testRemoveAtHead() async throws {
        var list = IntLinkedList([10, 20, 30])
        list.removeAt(0)
        #expect(list.count == 2)
        #expect(list[0] == 20)
        #expect(list[1] == 30)
    }
    
    @Test func testRemoveAtTail() async throws {
        var list = IntLinkedList([10, 20, 30])
        list.removeAt(2)
        #expect(list.count == 2)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
    }
    
    @Test func testRemoveAtMiddle() async throws {
        var list = IntLinkedList([10, 20, 30, 40, 50])
        list.removeAt(2)
        #expect(list.count == 4)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
        #expect(list[2] == 40)
        #expect(list[3] == 50)
    }

    // MARK: - Requirement 1: MutableCollection & RangeReplaceableCollection Tests

    @Test func testMutableCollectionSubscriptMutation() async throws {
        var list = IntLinkedList([1, 2, 3, 4])
        list[1] = 20
        #expect(list[1] == 20)
        #expect(list.count == 4)
        
        var strList = StringLinkedList(strings: ["alpha", "beta", "gamma"])
        strList[2] = std.string("delta")
        #expect(strList[2] == std.string("delta"))
    }

    @Test func testRangeReplaceableCollectionReplaceSubrange() async throws {
        var list = IntLinkedList([10, 20, 30, 40, 50])
        let start = list.index(after: list.startIndex) // 20
        let end = list.index(after: start) // 30
        list.replaceSubrange(start..<end, with: [99, 100])
        #expect(list.count == 6)
        #expect(list[0] == 10)
        #expect(list[1] == 99)
        #expect(list[2] == 100)
        #expect(list[3] == 30)

        // Test replaceSubrange at ends and empty ranges
        var strList = StringLinkedList(strings: ["A", "B", "C"])
        let startStr = strList.startIndex
        let endStr = strList.index(after: startStr)
        strList.replaceSubrange(startStr..<endStr, with: [std.string("X"), std.string("Y")])
        #expect(strList.count == 4)
        #expect(strList[0] == std.string("X"))
        #expect(strList[1] == std.string("Y"))
        #expect(strList[2] == std.string("B"))
        #expect(strList[3] == std.string("C"))

        // Replace entire range
        strList.replaceSubrange(strList.startIndex..<strList.endIndex, with: [std.string("Z")])
        #expect(strList.count == 1)
        #expect(strList[0] == std.string("Z"))

        // Test replaceSubrange with empty array (pure deletion)
        var delList = IntLinkedList([1, 2, 3, 4, 5])
        let dStart = delList.index(after: delList.startIndex) // 2
        let dEnd = unsafe delList.index(dStart, offsetBy: 2) // 4
        delList.replaceSubrange(dStart..<dEnd, with: [Int32]())
        #expect(delList.count == 3)
        #expect(delList[0] == 1)
        #expect(delList[1] == 4)
        #expect(delList[2] == 5)

        // Test replaceSubrange with empty range (pure insertion)
        let insPos = delList.index(after: delList.startIndex) // 4
        delList.replaceSubrange(insPos..<insPos, with: [20, 30])
        #expect(delList.count == 5)
        #expect(delList[0] == 1)
        #expect(delList[1] == 20)
        #expect(delList[2] == 30)
        #expect(delList[3] == 4)
        #expect(delList[4] == 5)

        // Test direct erase and insert methods
        var directList = IntLinkedList([100, 200, 300, 400])
        let eStart = directList.index(after: directList.startIndex)
        let eEnd = directList.index(after: eStart)
        directList.erase(eStart, eEnd)
        #expect(directList.count == 3)
        #expect(directList[0] == 100)
        #expect(directList[1] == 300)
        #expect(directList[2] == 400)
    }

    // MARK: - Requirement 2: C++ Bridging Annotations Tests

    @Test func testBridgingAnnotations() async throws {
        var list = IntLinkedList([10, 20, 30])
        let removed = list.pop(1)
        #expect(removed == 20)
        #expect(list.count == 2)
        #expect(list[0] == 10)
        #expect(list[1] == 30)
        
        list.insert(1, 15)
        #expect(list.count == 3)
        #expect(list[1] == 15)
        
        #expect(!list.isEmpty)
        list.removeAll()
        #expect(list.isEmpty)
        #expect(list.count == 0)
    }
}
