//
//  Heap.swift
//  SplitOff_project
//
//  Created by Davi Lyra Dubeux on 02/07/26.
//

import Foundation
import SwiftUI

class Heap<T: Comparable> {
    private var quantidade: Int
    private var array: [T]
    
    private func bottomUpHeapify(start: Int) -> Void {
        let v: T = array[start]
        var i = start
        
        while (2 * i <= quantidade) {
            var j: Int = 2 * i
            if (j < quantidade) {
                j += (array[j] > array[j + 1]) ? 1 : 0
            }
            if (v <= array[j]) { break }
            
            array[i] = array[j]
            i = j
        }
        
        array[i] = v
    }
    
    private func bottomUp() {
        var i = quantidade / 2
        while (i > 0) {
            bottomUpHeapify(start: i)
            i -= 1
        }
    }
    
    private func topDownHeapify(i: Int) -> Void {
        let v: T = array[i]
        var i = i
        
        while (i > 1 && v > array[i]) {
            array[i] = array[i / 2]
            i /= 2
        }
        
        array[i] = v
        
        print(array)
    }
    
    public init(dados: [T]) {
        array = [dados[0]]
        print (array.capacity)
        
        for dado in dados {
            array.append(dado)
        }
        for dado in dados {
            array.append(dado)
        }
        
        quantidade = array.count
        print(array)

        bottomUp()
    }
    
    public func insert(t: T) -> Void {
        quantidade += 1;
        
        if (quantidade >= array.capacity) {
            array.append(t)
        } else {
            array[quantidade] = t
        }
        
        topDownHeapify(i: quantidade)
    }
    
    public func pop() -> T? {
        if quantidade == 0 { return nil }
        
        let excluida: T = array[1]
        swap(&array[1], &array[quantidade])
        quantidade -= 1
        
        bottomUpHeapify(start: 1)
        return excluida
    }
    
    public func length() -> Int { return quantidade }
}

#Preview {
    Circle()
        .onAppear() {
            var dados = [1, 4, 6, 3, 7, 9, 2, 5, 8, 0]
//            let heap = Heap(dados: dados)
            print("oi")
        }
}
