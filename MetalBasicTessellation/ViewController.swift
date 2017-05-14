//
//  ViewController.swift
//  MetalBasicTessellation
//
//  Created by vladimir sierra on 5/10/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController {
  
  @IBOutlet weak var mtkView: MTKView!
  
  // Seven steps required to set up metal for rendering:
  
  // 1. Create a MTLDevice
  // 2. Create a CAMetalLayer
  // 3. Create a Vertex Buffer
  
  // 4. Create a Vertex Shader
  // 5. Create a Fragment Shader
  
  // 6. Create a Render Pipeline
  // 7. Create a Command Queue
  
  var device: MTLDevice! // to be initialized in viewDidLoad
  //var metalLayer: CAMetalLayer! // to be initialized in viewDidLoad
  var vertexBuffer: MTLBuffer! // to be initialized in viewDidLoad
  var library: MTLLibrary!
  
  // once we create a vertex and fragment shader (in the file Shaders.metal), we combine them in an object called render pipeline. In Metal the shaders are precompiled, and the render pipeline configuration is compiled after you first set it up. This makes everything extremely efficient
  
  var renderPipeline: MTLRenderPipelineState! // to be initialized in viewDidLoad
  var commandQueue: MTLCommandQueue! // to be initialized in viewDidLoad
  
  //var timer: CADisplayLink! // function to be called every time the device screen refreshes so we can redraw the screen
  

  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    /*
    if let window = view.window {
      let scale = window.screen.nativeScale // (2 for iPhone 5s, 6 and iPads;  3 for iPhone 6 Plus)
      let layerSize = view.bounds.size
      // apply the scale to increase the drawable texture size.
      view.contentScaleFactor = scale
      //metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
      //metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)
    } */
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    device = MTLCreateSystemDefaultDevice() // returns a reference to the default MTLDevice
    
    //device.supportsFeatureSet(MTLFeatureSet_iOS_GPUFamily3_v2)
    
    
    
    // set up layer to display metal content
    //metalLayer = CAMetalLayer()          // initialize metalLayer
    //metalLayer.device = device           // device the layer should use
    //metalLayer.pixelFormat = .bgra8Unorm // normalized 8 bit rgba
    //metalLayer.framebufferOnly = true    // set to true for performance issues
    //view.layer.addSublayer(metalLayer)   // add sublayer to main view's layer
    
    // precompile custom metal functions
    /*
    let path = Bundle.main.path(forResource: "TessellationFunctions", ofType: "metal")
    //let path = Bundle.main.path(forResource: "TessellationFunctions", ofType: "metal")
      do {
        let source = try String(contentsOfFile: path!, encoding: .utf8)
        //print ("...functions path is \(path)")
        library = try device.makeLibrary(source: source, options: nil)
      } catch let error as NSError {
        print("library error: " + error.description)
      }
    */
    /*
    //////
    if let filepath = Bundle.main.path(forResource: "TessellationFunctions.metal", ofType: nil) {
      do {
        let contents = try String(contentsOfFile: filepath)
        print ("............")
        print(contents)
        print ("............")
      } catch {
        // contents could not be loaded
      }
    } else {
      // example.txt not found!
      print ("......functions file not found")
    }
    //////
    */
    
    /*
    let bundlepath = Bundle.main.bundlePath
    let filepath = bundlepath.appendingFormat("/TessellationFunctions.metal")
    do {
      //let cc = try String(conte)
      let contents = try String(contentsOfFile: filepath, encoding: .utf8)
      print ("............")
      print (filepath)
      print(contents)
      print ("............")
      } catch {
      // contents could not be loaded
        print ("......functions file not found \(filepath)")
        
        
    } */
    
    // access precompiled shaders included in project through device.newDefaultLibrary()!
    let defaultLibrary = device.newDefaultLibrary()! // MTLLibrary object with precompiled shaders
    
    
    let fragmentProgram = defaultLibrary.makeFunction(name: "tessellation_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "tessellation_vertex_triangle")
    
    // Setup Compute Pipeline
    let kernelFunction = defaultLibrary.makeFunction(name: "tessellation_kernel_triangle")
    var computePipeline: MTLComputePipelineState?
    do {
      computePipeline = try device.makeComputePipelineState(function: kernelFunction!)
    } catch let error as NSError {
      print("compute pipeline error: " + error.description)
    }
    
    // Setup Vertex Descriptor
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float4
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stride = 4*MemoryLayout<Float>.size
    
    // Setup Render Pipeline
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
    //renderPipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "tessellation_fragment")
    renderPipelineDescriptor.fragmentFunction = fragmentProgram
    //renderPipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "tessellation_vertex_triangle")
    renderPipelineDescriptor.vertexFunction = vertexProgram
    
    //renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // normalized 8 bit rgba
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
    
    renderPipelineDescriptor.isTessellationFactorScaleEnabled = false
    renderPipelineDescriptor.tessellationFactorFormat = .half
    renderPipelineDescriptor.tessellationControlPointIndexType = .none
    renderPipelineDescriptor.tessellationFactorStepFunction = .constant
    renderPipelineDescriptor.tessellationOutputWindingOrder = .clockwise
    renderPipelineDescriptor.tessellationPartitionMode = .fractionalEven
    renderPipelineDescriptor.maxTessellationFactor = 64;
    
    // Compile renderPipeline
    do {
      renderPipeline = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch let error as NSError {
      print("render pipeline error: " + error.description)
    }
    
    // Setup Buffers
    let tessellationFactorsBuffer = device.makeBuffer(length: 256, options: MTLResourceOptions.storageModePrivate)
    let controlPointPositions: [Float] = [
      -0.8, -0.8, 0.0, 1.0,   // lower-left
      0.0,  0.8, 0.0, 1.0,   // upper-middle
      0.8, -0.8, 0.0, 1.0,   // lower-right
    ]
    let controlPointsBuffer = device.makeBuffer(bytes: controlPointPositions, length:256 , options: [])
    
    // Tessellation Pass
    let commandBuffer = commandQueue.makeCommandBuffer()
    
    let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
    computeCommandEncoder.setComputePipelineState(computePipeline!)
    
    let edgeFactor: [Float] = [16.0]
    let insideFactor: [Float] = [8.0]
    computeCommandEncoder.setBytes(edgeFactor, length: MemoryLayout<Float>.size, at: 0)
    computeCommandEncoder.setBytes(insideFactor, length: MemoryLayout<Float>.size, at: 1)
    computeCommandEncoder.setBuffer(tessellationFactorsBuffer, offset: 0, at: 2)
    computeCommandEncoder.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    computeCommandEncoder.endEncoding()
    
    let renderPassDescriptor = mtkView.currentRenderPassDescriptor
    let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
    renderCommandEncoder.setRenderPipelineState(renderPipeline!)
    renderCommandEncoder.setVertexBuffer(controlPointsBuffer, offset: 0, at: 0)
    renderCommandEncoder.setTriangleFillMode(.lines)
    renderCommandEncoder.setTessellationFactorBuffer(tessellationFactorsBuffer, offset: 0, instanceStride: 0)
    renderCommandEncoder.drawPatches(numberOfPatchControlPoints: 3, patchStart: 0, patchCount: 1, patchIndexBuffer: nil, patchIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)
    renderCommandEncoder.endEncoding()
    
    commandBuffer.present(mtkView.currentDrawable!)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    /*
    // finally create an ordered list of commands forthe GPU to execute
    commandQueue = device.makeCommandQueue()
    
    timer = CADisplayLink(target: self, selector: #selector(ViewController.gameloop)) // call gameloop every time the screen refreshes
    timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    
    */
  
    
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /*
  func render() {
    guard let drawable = metalLayer?.nextDrawable() else { return } // returns the texture to draw into in order for something to appear on the screen
    //objectToDraw.render(commandQueue: commandQueue, renderPipeline: renderPipeline, drawable: drawable, clearColor: nil)
  }
  
  // this is the routine that gets run every time the screen refreshes
  func gameloop() {
    autoreleasepool {
      self.render()
    }
  } */


}

