//
//  Heap.swift
//  SplitOff_project
//
//  Created by Davi Lyra Dubeux on 02/07/26.
//

import Foundation
import SwiftUI

class Heap<T> {
    var heap: [T] = []
    var compare: (T, T) -> Bool

    init(comparePor: @escaping (T, T) -> Bool) {
        compare = comparePor
    }

    func insert(_ element: T) {
        heap.append(element)
        var currentIndex = heap.count - 1

        while currentIndex > 0
            && compare(heap[currentIndex], heap[(currentIndex - 1) / 2])
        {
            heap.swapAt(currentIndex, (currentIndex - 1) / 2)
            currentIndex = (currentIndex - 1) / 2
        }
    }

    func remove() -> T? {
        guard !heap.isEmpty else {
            return nil
        }

        let topElement = heap[0]

        if heap.count == 1 {
            heap.removeFirst()
        } else {

            heap[0] = heap.removeLast()
            var currentIndex = 0

            while true {
                let leftChildIndex = 2 * currentIndex + 1
                let rightChildIndex = 2 * currentIndex + 2

                var maxIndex = currentIndex
                if leftChildIndex < heap.count
                    && compare(heap[leftChildIndex], heap[maxIndex])
                {
                    maxIndex = leftChildIndex
                }
                if rightChildIndex < heap.count
                    && compare(heap[rightChildIndex], heap[maxIndex])
                {
                    maxIndex = rightChildIndex
                }

                if maxIndex == currentIndex {
                    break
                }

                heap.swapAt(currentIndex, maxIndex)
                currentIndex = maxIndex
            }
        }

        return topElement
    }

    func peek() -> T? {
        return heap.first
    }

    var isEmpty: Bool {
        return heap.isEmpty
    }
}
