//
//  CGPointExtensions.swift
//  SumoAR
//
//  Created by Enzo Maruffa Moreira on 13/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import UIKit

func + (left: CGPoint, right: CGPoint) -> CGPoint
{
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func + (left: CGPoint, scalar: CGFloat) -> CGPoint
{
    return CGPoint(x: left.x + scalar, y: left.y + scalar)
}

func - (left: CGPoint, scalar: CGFloat) -> CGPoint
{
    return CGPoint(x: left.x - scalar, y: left.y - scalar)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint
{
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (left: CGPoint, scalar: CGFloat) -> CGPoint
{
    return CGPoint(x: left.x * scalar, y: left.y * scalar)
}

func / (left: CGPoint, scalar: CGFloat) -> CGPoint
{
    return CGPoint(x: left.x / scalar, y: left.y / scalar)
}


extension CGPoint {
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return CGFloat(sqrt(pow(x - point.x, 2) + pow(y - point.y, 2)))
    }
    
    func normalized() -> CGPoint {
        let vectorLength = self.module()
        return CGPoint(x: x / vectorLength, y: y / vectorLength)
    }
    
    func module() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func forcedLength(length: CGFloat) -> CGPoint {
        return self.normalized() * length
    }
    
    static func randomPoint(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat.random(in: minX...maxX), y: CGFloat.random(in: minY...maxY))
    }
    
    static func randomPoint(totalLength: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -1...1)).forcedLength(length: totalLength)
    }
    
    static func randomRoundedPoint(minX: Int, maxX: Int, minY: Int, maxY: Int) -> CGPoint {
        return CGPoint(x: Int.random(in: minX...maxX), y: Int.random(in: minY...maxY))
    }
    
    func toCGVector() -> CGVector {
        return CGVector(dx: x, dy: y)
    }
    
}

//

func + (left: CGVector, right: CGVector) -> CGVector
{
    return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
}

func + (left: CGVector, scalar: CGFloat) -> CGVector
{
    return CGVector(dx: left.dx + scalar, dy: left.dy + scalar)
}

func - (left: CGVector, scalar: CGFloat) -> CGVector
{
    return CGVector(dx: left.dx - scalar, dy: left.dy - scalar)
}

func - (left: CGVector, right: CGVector) -> CGVector
{
    return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
}

func * (left: CGVector, scalar: CGFloat) -> CGVector
{
    return CGVector(dx: left.dx * scalar, dy: left.dy * scalar)
}

func / (left: CGVector, scalar: CGFloat) -> CGVector
{
    return CGVector(dx: left.dx / scalar, dy: left.dy / scalar)
}


extension CGVector {
    
    func distanceTo(_ point: CGVector) -> CGFloat {
        return CGFloat(sqrt(pow(dx - point.dx, 2) + pow(dy - point.dy, 2)))
    }
    
    func normalized() -> CGVector {
        let vectorLength = self.module()
        return CGVector(dx: dx / vectorLength, dy: dy / vectorLength)
    }
    
    func module() -> CGFloat {
        return sqrt(dx*dx + dy*dy)
    }
    
    func forcedLength(length: CGFloat) -> CGVector {
        return self.normalized() * length
    }
    
    static func randomVector(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) -> CGVector {
        return CGVector(dx: CGFloat.random(in: minX...maxX), dy: CGFloat.random(in: minY...maxY))
    }
    
    static func randomVector(totalLength: CGFloat) -> CGVector {
        return CGVector(dx: CGFloat.random(in: -1...1), dy: CGFloat.random(in: -1...1)).forcedLength(length: totalLength)
    }

    func angle() -> CGFloat {
        return atan2(dy, dx)
    }
    
    func toCGPoint() -> CGPoint {
        return CGPoint(x: dx, y: dy)
    }
    
}
