//
//  APNGImageViewTests.swift
//  
//
//  Created by Wang Wei on 2021/10/29.
//

import Foundation
import XCTest
import Delegate
@testable import APNGKit

#if canImport(UIKit)
class ViewControllerStub {
    
    var window: UIWindow!
    
    func setupViewController() -> UIViewController {
        let rootViewController =  UIViewController()
        return setupViewController(rootViewController)
    }
    
    func setupViewController(_ input: UIViewController) -> UIViewController {

        input.loadViewIfNeeded()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = input
        window.makeKeyAndVisible()
        return input
    }
    
    func resetViewController() {
        window.rootViewController = nil
        window = nil
    }
}
#endif

#if canImport(AppKit)

class ViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: .init(x: 0, y: 0, width: 100, height: 100))
    }
}

class ViewControllerStub {
    
    var window: NSWindow!
    
    func setupViewController() -> NSViewController {
        let rootViewController =  ViewController()
        return setupViewController(rootViewController)
    }
    
    func setupViewController(_ input: ViewController) -> NSViewController {

        _ = input.view
        window = NSWindow(contentRect: .init(x: 0, y: 0, width: 100, height: 100), styleMask: .borderless, backing: .buffered, defer: false)
        window.contentViewController = input
        return input
    }
    
    func resetViewController() {
        window = nil
    }
}
#endif

class APNGImageViewTests: XCTestCase {
    
    var viewControllerStub = ViewControllerStub()
    weak var imageView: APNGImageView?
    
    override func tearDown() {
        imageView = nil
    }
    
    func testInit() throws {
        let imageView = APNGImageView(frame: .zero)
        XCTAssertNil(imageView.image)
        XCTAssertFalse(imageView.isAnimating)
    }
    
    func testInitWithImage() throws {
        let apng = createBallImage()
        let imageView = APNGImageView(image: apng)
        XCTAssertEqual(imageView.intrinsicContentSize, apng.size)
        XCTAssertTrue(imageView.isAnimating)
    }
    
    func testLayoutByContentSize() throws {
        
        let apng = createBallImage()
        let imageView = APNGImageView(image: apng)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let vc = viewControllerStub.setupViewController()
        vc.view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        
        XCTAssertEqual(imageView.bounds, .zero)
        #if canImport(UIKit)
        vc.view.layoutIfNeeded()
        #elseif canImport(AppKit)
        vc.view.layoutSubtreeIfNeeded()
        #endif
        XCTAssertEqual(imageView.bounds, .init(origin: .zero, size: apng.size))
    }
    
    func testReleaseWhenNotAnimating() throws {
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(frame: .zero)
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testReleaseWhenInitImage() throws {
        let apng = createBallImage()
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(image: apng)
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testReleaseWhenInitImageWithoutAnimation() throws {
        let apng = createBallImage()
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(image: apng, autoStartAnimating: false)
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testReleaseWhenSetImageWithoutAnimation() throws {
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(frame: .zero)
        imageView?.autoStartAnimationWhenSetImage = false
        
        let apng = createBallImage()
        imageView?.image = apng
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testSwitchingImage() throws {
        let ballAPNG = createBallImage()
        let minimalAPNG = createMinimalImage()
        
        let imageView = APNGImageView(image: ballAPNG)
        XCTAssertTrue(imageView.isAnimating)
        XCTAssertTrue(ballAPNG.owner === imageView)
        XCTAssertNil(minimalAPNG.owner)

        imageView.image = minimalAPNG
        XCTAssertTrue(imageView.isAnimating)
        XCTAssertNil(ballAPNG.owner)
        XCTAssertTrue(minimalAPNG.owner === imageView)
        
        imageView.image = nil
        XCTAssertFalse(imageView.isAnimating)
        XCTAssertNil(ballAPNG.owner)
        XCTAssertNil(minimalAPNG.owner)
    }
    
    func testSettingImageWithOwner() throws {
        let apng = createBallImage()
        
        let imageView1 = APNGImageView(image: apng)
        let imageView2 = APNGImageView(image: apng)
        let imageView3 = APNGImageView(image: createBallImage())
        
        XCTAssertNotNil(imageView1.image)
        XCTAssertNil(imageView2.image)
        XCTAssertNotNil(imageView3.image)
    }
}

class DeinitInspectableAPNGImageView: APNGImageView {
    let onDeinit = Delegate<(), Void>()
    
    deinit {
        onDeinit()
    }
}
