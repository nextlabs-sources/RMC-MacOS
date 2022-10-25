//
//  PreviousViewed.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 05/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class PreviousViewed {
    
    typealias AbsolutePath = (navType: RepoNavItem, navName: String, pathId: String?)
    
    private var currentPosition = 0
    private var viewedHistory = [AbsolutePath]()
    
    func append(with path: AbsolutePath) {
        // remove behind nodes
        if currentPosition < viewedHistory.count - 1 {
            var removeCount = viewedHistory.count - currentPosition - 1
            while removeCount > 0 {
                viewedHistory.removeLast()
                removeCount -= 1
            }
        }
        
        viewedHistory.append(path)
        currentPosition = viewedHistory.count - 1
    }
    
    // TODO: remove failed to view path
    func removeCurrent() {
    }
    
    func moveForward() -> Bool {
        if canMoveForward() {
            currentPosition += 1
            return true
        }
        
        return false
    }
    
    func moveBack() -> Bool {
        if canMoveBack() {
            currentPosition -= 1
            return true
        }
        
        return false
    }
    
    func canMoveForward() -> Bool {
        return (currentPosition + 1) < viewedHistory.count
    }
    
    func canMoveBack() -> Bool {
        return (currentPosition - 1) >= 0
    }
    
    func getCurrentViewedPath() -> AbsolutePath {
        return getViewedPath(with: currentPosition)
    }
    
    private func getViewedPath(with index: Int) -> AbsolutePath {
        let path = viewedHistory[index]
        return path
    }
}
