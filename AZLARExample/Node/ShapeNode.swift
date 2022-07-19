//
//  ShapeNode.swift
//  Ruler
//
//  Created by lizihong on 2022/7/19.
//  Copyright © 2022 Tbxark. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

/**
多边形节点
 */
class ShapeNode: SCNNode {
    /// 点
    var pointNodes: [SCNNode] = []
    /// 线
    var lineNodes: [SCNNode] = []
    /// 文字
    var textNodes: [SCNNode] = []
    
    init(vectors: [SCNVector3], color: UIColor, font: UIFont, unit: MeasurementUnit.Unit = MeasurementUnit.Unit.centimeter) {
        super.init()
        let scale = 1/400.0
        let scaleVector = SCNVector3(scale, scale, scale)

        func buildSCNSphere(color: UIColor) -> SCNSphere {
            let dot = SCNSphere(radius:1)
            dot.firstMaterial?.diffuse.contents = color
            dot.firstMaterial?.lightingModel = .constant
            dot.firstMaterial?.isDoubleSided = true
            return dot
        }
        
        // 添加点
        for vector in vectors {
            let pointNode = SCNNode(geometry: buildSCNSphere(color: color))
            pointNode.scale = scaleVector
            pointNode.position = vector
            pointNodes.append(pointNode)
        }
        
        for i in 0..<pointNodes.count {
            // 线
            let preNode = pointNodes[(i-1+pointNodes.count)%pointNodes.count]
            let curNode = pointNodes[i]
            
            let lineNode = self.lineBetweenNodeA(nodeA: preNode, nodeB: curNode, color: color)
            lineNodes.append(lineNode)
            
            // 距离文字
            let posStart = preNode.position
            let posEnd = curNode.position
            let middle = SCNVector3((posStart.x+posEnd.x)/2.0, (posStart.y+posEnd.y)/2.0+0.002, (posStart.z+posEnd.z)/2.0)
            let length = curNode.position.distanceFromPos(pos: preNode.position)
            let lengthString = MeasurementUnit(meterUnitValue: length).string(type: unit)
            let text = SCNText (string: lengthString, extrusionDepth: 0.1)
            text.font = font
            text.firstMaterial?.diffuse.contents = UIColor.white
            text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            text.truncationMode = CATextLayerTruncationMode.middle.rawValue
            text.firstMaterial?.isDoubleSided = true
            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
            textNode.position = middle
            self.textNodes.append(textNode)
        }
        
        for lineNode in lineNodes {
            self.addChildNode(lineNode)
        } 
    
        for node in pointNodes {
            self.addChildNode(node)
        }
        
        for node in textNodes {
            self.addChildNode(node)
        }
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func lineBetweenNodeA(nodeA: SCNNode, nodeB: SCNNode, color: UIColor) -> SCNNode {
        
        return CylinderLine(parent: self,
                            v1: nodeA.position,
                            v2: nodeB.position,
                            radius: 0.001,
                            radSegmentCount: 16,
                            color: color)
        
    }
    
    /// 根据摄像头方向，更新ui
    func update(camera: ARCamera) {
        // 更新文字的方向(总是对着摄像头)
        let tilt = abs(camera.eulerAngles.x)
        let threshold1: Float = Float.pi / 2 * 0.65
        let threshold2: Float = Float.pi / 2 * 0.75
        let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
        var angle: Float = 0
        
        switch tilt {
        case 0..<threshold1:
            angle = camera.eulerAngles.y
        case threshold1..<threshold2:
            let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
            let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
            angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
        default:
            angle = yaw
        }
        
        for textNode in self.textNodes {
            textNode.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0))
        }
    }
    
    private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {

        var normalized = angle
        while abs(normalized - ref) > Float.pi / 4 {
            if angle > ref {
                normalized -= Float.pi / 2
            } else {
                normalized += Float.pi / 2
            }
        }
        return normalized
    }
}
