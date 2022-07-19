//
//  ViewController.swift
//  AZLARExample
//
//  Created by lizihong on 2022/7/15.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    var sceneView: ARSCNView!
    var planes = [UUID: Plane]() // 字典，存储场景中当前渲染的所有平面
    
    private var frameCount = 0
    //private let shotImageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 192, height: 144))
    //private let shotLayer = CAShapeLayer.init()
    
    private var tmpShapeNode: ShapeNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView = ARSCNView.init(frame: self.view.bounds)
        self.sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.sceneView)
        
        setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func setupScene() {
        // 设置 ARSCNViewDelegate——此协议会提供回调来处理新创建的几何体
        sceneView.delegate = self
        
        // 显示统计数据（statistics）如 fps 和 时长信息
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        // 开启 debug 选项以查看世界原点并渲染所有 ARKit 正在追踪的特征点
        //sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    func setupSession() {
        // 创建 session 配置（configuration）实例
        let configuration = ARWorldTrackingConfiguration()
        
        // 明确表示需要追踪水平面。设置后 scene 被检测到时就会调用 ARSCNViewDelegate 方法
        configuration.planeDetection = [.horizontal, .vertical]
        
        // 运行 view 的 session
        sceneView.session.run(configuration)
    }

    func updateRectangle() {
        // 一定帧数才做一次识别(识别比较耗性能)
        if frameCount%20 == 0 {
            if let buffer = self.sceneView.session.currentFrame?.capturedImage {
                let image = CIImage.init(cvPixelBuffer: buffer)
                let detector = CIDetector.init(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorMinFeatureSize: 0.25, CIDetectorMaxFeatureCount: 1])
                let rectangles = detector?.features(in: image) as? [CIRectangleFeature]
                var rectangleRect: Float = 0
                var rectangle: CIRectangleFeature?
                for rect in rectangles ?? [] {
                    
                    let p1 = rect.topLeft
                    let p2 = rect.topRight
                    
                    //let p3 = rect.bottomRight
                    let p4 = rect.bottomLeft
                    let width1 = hypotf(Float(p1.x-p2.x), Float(p1.y-p2.y))
                    //let width2 = hypotf(Float(p3.x-p4.x), Float(p3.y-p4.y))
                    
                    let height1 = hypotf(Float(p1.x-p4.x), Float(p1.y-p4.y))
                    //let height2 = hypotf(Float(p2.x-p3.x), Float(p2.y-p3.y))
                    
                    //if fabsf(width1-width2)/width1 < 0.08 && fabsf(height1-height2)/height1 < 0.08 {
                        // 宽高的误差在8%内
                    let currentRectangleRect = height1+width1
                    // 找出最大的矩形
                    if rectangleRect < currentRectangleRect {
                        rectangleRect = currentRectangleRect
                        rectangle = rect
                    }
                    //}
                    
                }
                
                if let rectangle = rectangle {
                    print("width: \(image.extent.width), height: \(image.extent.height)")
                    print("\(rectangle.bounds)")
                    let imageWidth = image.extent.width
                    let imageHeight = image.extent.height
                    
                    // 由于图片是1920*1080横着的图，需要转换
                    let tl = CGPoint.init(x: rectangle.bottomLeft.y, y: rectangle.bottomLeft.x)
                    let tr = CGPoint.init(x: rectangle.topLeft.y, y: rectangle.topLeft.x)
                    let br = CGPoint.init(x: rectangle.topRight.y, y: rectangle.topRight.x)
                    let bl = CGPoint.init(x: rectangle.bottomRight.y, y: rectangle.bottomRight.x)
                    
                    let viewWidth = self.sceneView.bounds.size.width
                    
                    let scaleH = imageWidth/self.sceneView.bounds.size.height
                    
                    let totalViewWidth = viewWidth*scaleH
                    let startX: CGFloat = (imageHeight-totalViewWidth)/2
                    
                    // 显示的范围 [startX, startX+totalViewWidth/imageHeight]
                    
                    let topLeft = CGPoint.init(x: (tl.x-startX)/scaleH, y: tl.y/scaleH)
                    let topRight = CGPoint.init(x: (tr.x-startX)/scaleH, y: tr.y/scaleH)
                    let bottomLeft = CGPoint.init(x: (bl.x-startX)/scaleH, y: bl.y/scaleH)
                    let bottomRight = CGPoint.init(x: (br.x-startX)/scaleH, y: br.y/scaleH)
                    
                    //                var transform = CGAffineTransform.init(translationX: 0, y: 0)
                    //                //transform = transform.scaledBy(x: 1, y: -1)
                    //                transform = transform.scaledBy(x: scaleH, y: scaleH)
                    //                
                    //                let topLeft = rectangle.topLeft.applying(transform)
                    //                let topRight = rectangle.topRight.applying(transform)
                    //                let bottomLeft = rectangle.bottomLeft.applying(transform)
                    //                let bottomRight = rectangle.bottomRight.applying(transform)
                    
//                    print("\(topLeft), \(topRight), \(bottomLeft), \(bottomRight)")
//                    let path = UIBezierPath.init()
//                    path.move(to: topLeft)
//                    path.addLine(to: topRight)
//                    path.addLine(to: bottomRight)
//                    path.addLine(to: bottomLeft)
//                    path.addLine(to: topLeft)
//                    let layer = self.rectLayer
//                    layer.backgroundColor = UIColor.clear.cgColor
//                    layer.frame = self.view.bounds
//                    layer.path = path.cgPath
//                    layer.fillColor = UIColor.clear.cgColor
//                    layer.strokeColor = UIColor.red.cgColor
//                    layer.lineWidth = 2
//                    self.view.layer.addSublayer(layer)
                    
                    self.updateShapeNode(points: [topLeft, topRight, bottomRight, bottomLeft])
                } else {
                    //self.rectLayer.removeFromSuperlayer()
                }
                // 方便debug观看的截图
//                let image_ui = UIImage.init(ciImage: image)
//                self.shotImageView.contentMode = .scaleAspectFit
//                self.shotImageView.image = image_ui
//                self.view.addSubview(self.shotImageView)
//                let path = UIBezierPath.init()
//                
//                for rect in rectangles ?? [] {
//                    path.move(to: CGPoint.init(x: rect.topLeft.x/10, y: 144-rect.topLeft.y/10))
//                    path.addLine(to: CGPoint.init(x: rect.topRight.x/10, y: 144-rect.topRight.y/10))
//                    path.addLine(to: CGPoint.init(x: rect.bottomRight.x/10, y: 144-rect.bottomRight.y/10))
//                    path.addLine(to: CGPoint.init(x: rect.bottomLeft.x/10, y: 144-rect.bottomLeft.y/10))
//                    path.addLine(to: CGPoint.init(x: rect.topLeft.x/10, y: 144-rect.topLeft.y/10))
//                }
//                let layer = self.shotLayer
//                layer.backgroundColor = UIColor.clear.cgColor
//                layer.frame = self.shotImageView.bounds
//                layer.path = path.cgPath
//                layer.fillColor = UIColor.clear.cgColor
//                layer.strokeColor = UIColor.red.cgColor
//                layer.lineWidth = 1
//                self.shotImageView.layer.addSublayer(layer)
            }
            
        }
        frameCount += 1
        
        self.updateShapeCamera()
    }
    
    private func updateShapeNode(points: [CGPoint]) {
        var vectors: [SCNVector3] = []
        for point in points {
            if let vector = sceneView.worldPositionFromScreenPosition(point, objectPos: nil).position {
                vectors.append(vector)
            }
        }
        if vectors.count > 3 {
            let shapeNode = ShapeNode.init(vectors: vectors, color: UIColor.white, font: UIFont.boldSystemFont(ofSize: 10), unit: MeasurementUnit.Unit.centimeter)
            
            self.tmpShapeNode?.removeFromParentNode()
            self.sceneView.scene.rootNode.addChildNode(shapeNode)
            self.tmpShapeNode = shapeNode
        }
    }
    
    private func updateShapeCamera() {
        if let camera = self.sceneView.session.currentFrame?.camera {
           self.tmpShapeNode?.update(camera: camera) 
        }
    }

    // MARK: - ARSCNViewDelegate
    
    /**
     实现此方法来为给定 anchor 提供自定义 node。
     
     @discussion 此 node 会被自动添加到 scene graph 中。
     如果没有实现此方法，则会自动创建 node。
     如果返回 nil，则会忽略此 anchor。
     @param renderer 将会用于渲染 scene 的 renderer。
     @param anchor 新添加的 anchor。
     @return 将会映射到 anchor 的 node 或 nil。
     */
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        return nil
//    }
    
    /// 每一帧更新回调
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // 切换到主线程做ui更新操作
            self.updateRectangle()
        }
    }
    
    /**
     将新 node 映射到给定 anchor 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 映射到 anchor 的 node。
     @param anchor 新添加的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("添加anchor\n \(anchor)")
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        // 检测到新平面时创建 SceneKit 平面以实现 3D 视觉化
//        let plane = Plane(withAnchor: anchor)
//        planes[anchor.identifier] = plane
//        node.addChildNode(plane)
    }
    
    /**
     使用给定 anchor 的数据更新 node 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 更新后的 node。
     @param anchor 更新后的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        
        // anchor 更新后也需要更新 3D 几何体。例如平面检测的高度和宽度可能会改变，所以需要更新 SceneKit 几何体以匹配
        plane.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    /**
     从 scene graph 中移除与给定 anchor 映射的 node 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 被移除的 node。
     @param anchor 被移除的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // 如果多个独立平面被发现共属某个大平面，此时会合并它们，并移除这些 node
        planes.removeValue(forKey: anchor.identifier)
    }
    
    /**
     将要用给定 anchor 的数据来更新时 node 调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 即将更新的 node。
     @param anchor 被更新的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

