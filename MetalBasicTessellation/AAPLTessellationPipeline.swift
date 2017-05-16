//  Converted with Swiftify v1.0.6331 - https://objectivec2swift.com/
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Tessellation Pipeline for MetalBasicTessellation.
 The exposed properties are user-defined via the ViewController UI elements.
 The compute pipelines are built with a compute kernel (one for triangle patches; one for quad patches).
 The render pipelines are built with a post-tessellation vertex function (one for triangle patches; one for quad patches) and a fragment function. The render pipeline descriptor also configures tessellation-specific properties.
 The tessellation factors buffer is dynamically populated by the compute kernel.
 The control points buffer is populated with static position data.
 */


import Metal
import MetalKit


class AAPLTessellationPipeline: NSObject, MTKViewDelegate {
  
  var patchType = MTLPatchType(rawValue: 0)!
  var isWireframe: Bool = false
  var edgeFactor: [Float] = [0.0]
  var insideFactor: [Float] = [0.0]
  
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  let library: MTLLibrary
  
  /*
  //private weak var device: MTLDevice?
  //private weak var commandQueue: MTLCommandQueue!
  //private weak var library: MTLLibrary?
  private weak var computePipelineTriangle: MTLComputePipelineState?
  private weak var computePipelineQuad: MTLComputePipelineState?
  private weak var renderPipelineTriangle: MTLRenderPipelineState?
  private weak var renderPipelineQuad: MTLRenderPipelineState?
  private weak var tessellationFactorsBuffer: MTLBuffer?
  private weak var controlPointsBufferTriangle: MTLBuffer?
  private weak var controlPointsBufferQuad: MTLBuffer?
  */
  
  var computePipelineTriangle: MTLComputePipelineState?
  var computePipelineQuad: MTLComputePipelineState?
  var renderPipelineTriangle: MTLRenderPipelineState?
  var renderPipelineQuad: MTLRenderPipelineState?
  var tessellationFactorsBuffer: MTLBuffer?
  var controlPointsBufferTriangle: MTLBuffer?
  var controlPointsBufferQuad: MTLBuffer?
  
  init? (mtkView view: MTKView) {
    
    device = MTLCreateSystemDefaultDevice()!
    commandQueue = device.makeCommandQueue() // Create a new command queue
    library = device.newDefaultLibrary()! // Load the default library
    
    super.init()
    
    // Initialize properties
    isWireframe = true
    patchType = .triangle
    edgeFactor = [2.0]
    insideFactor = [2.0]
    // Setup Metal
    
    
    if !didSetupMetal() {
      return nil
    }
    
    // Assign device and delegate to MTKView
    view.device = device
    view.delegate = self
    
    // Setup compute pipelines
    if !didSetupComputePipelines() {
      return nil
    }
    
    // Setup render pipelines
    if !didSetupRenderPipelines(with: view) {
      return nil
    }
    
    // Setup Buffers
    setupBuffers()
    
  }
  
  // MARK: Setup methods
  func didSetupMetal() -> Bool {

    #if TARGET_OS_IOS
      if !device?.supportsFeatureSet(MTLFeatureSet_iOS_GPUFamily3_v2) {
        print("Tessellation is not supported on this device")
        return false
      }
    #elseif TARGET_OS_OSX
      if !device?.supportsFeatureSet(MTLFeatureSet_OSX_GPUFamily1_v1) {
        print("Tessellation is not supported on this device")
        return false
      }
    #endif
    
    return true
  }
  
  func didSetupComputePipelines() -> Bool {
    // Create compute pipeline for triangle-based tessellation
    let kernelFunctionTriangle = library.makeFunction(name: "tessellation_kernel_triangle")

    do {
      computePipelineTriangle = try device.makeComputePipelineState(function: kernelFunctionTriangle!)
    } catch let error as NSError {
      print("compute pipeline error: " + error.description)
    }
    // Create compute pipeline for quad-based tessellation
    let kernelFunctionQuad = library.makeFunction(name: "tessellation_kernel_quad")
    do {
      computePipelineQuad = try device.makeComputePipelineState(function: kernelFunctionQuad!)
    } catch let error as NSError {
      print("compute pipeline error: " + error.description)
    }
    
    
    return true
  }
  
  func didSetupRenderPipelines(with view: MTKView) -> Bool {
    
    let vertexProgramTriangle = library.makeFunction(name: "tessellation_vertex_triangle")
    let vertexProgramQuad = library.makeFunction(name: "tessellation_vertex_quad")
    let fragmentProgram = library.makeFunction(name: "tessellation_fragment")

    // Create a reusable vertex descriptor for the control point data
    // This describes the inputs to the post-tessellation vertex function, declared with the 'stage_in' qualifier
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float4
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stride = 4 * MemoryLayout<Float>.size
    
    // Create a reusable render pipeline descriptor
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    
    // Configure common render properties
    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
    renderPipelineDescriptor.sampleCount = view.sampleCount
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
    renderPipelineDescriptor.fragmentFunction = fragmentProgram
    
    // Configure common tessellation properties
    renderPipelineDescriptor.isTessellationFactorScaleEnabled = false
    renderPipelineDescriptor.tessellationFactorFormat = .half
    renderPipelineDescriptor.tessellationControlPointIndexType = .none
    renderPipelineDescriptor.tessellationFactorStepFunction = .constant
    renderPipelineDescriptor.tessellationOutputWindingOrder = .clockwise
    renderPipelineDescriptor.tessellationPartitionMode = .fractionalEven
    
    
    #if TARGET_OS_IOS
      // In iOS, the maximum tessellation factor is 16
      renderPipelineDescriptor.maxTessellationFactor = 16
    #elseif TARGET_OS_OSX
      // In OS X, the maximum tessellation factor is 64
      renderPipelineDescriptor.maxTessellationFactor = 64
    #endif

    // Create render pipeline for triangle-based tessellation
    renderPipelineDescriptor.vertexFunction = vertexProgramTriangle
    
    // Compile renderPipeline for triangle-based tessellation
    do {
      renderPipelineTriangle = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch let error as NSError {
      print("render pipeline error: " + error.description)
    }
    
    // Create render pipeline for quad-based tessellation
    renderPipelineDescriptor.vertexFunction = vertexProgramQuad
    
    // Compile renderPipeline for quad-based tessellation
    do {
      renderPipelineQuad = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch let error as NSError {
      print("render pipeline error: " + error.description)
    }
    

    return true
  }
  
  func setupBuffers() {
    // Allocate memory for the tessellation factors buffer
    // This is a private buffer whose contents are later populated by the GPU (compute kernel)
    tessellationFactorsBuffer = device.makeBuffer(length: 256, options: MTLResourceOptions.storageModePrivate)
    tessellationFactorsBuffer?.label = "Tessellation Factors"
    // Allocate memory for the control points buffers
    // These are shared or managed buffers whose contents are immediately populated by the CPU
    let controlPointsBufferOptions: MTLResourceOptions = .storageModeShared
    
    /*
    #if TARGET_OS_IOS
      // In iOS, the storage mode can only be shared
      controlPointsBufferOptions = .storageModeShared
    #elseif TARGET_OS_OSX
      // In OS X, the storage mode can be shared or managed, but managed may yield better performance
      controlPointsBufferOptions = .storageModeManaged
    #endif
    */
    
    let controlPointPositionsTriangle: [Float] = [-0.8, -0.8, 0.0, 1.0,             // lower-left
      0.0, 0.8, 0.0, 1.0,             // upper-middle
      0.8, -0.8, 0.0, 1.0]
    controlPointsBufferTriangle = device.makeBuffer(bytes: controlPointPositionsTriangle, length: 12 * MemoryLayout<Float>.size, options: controlPointsBufferOptions)
    controlPointsBufferTriangle?.label = "Control Points Triangle"
    let controlPointPositionsQuad: [Float] = [-0.8, 0.8, 0.0, 1.0,             // upper-left
      0.8, 0.8, 0.0, 1.0,             // upper-right
      0.8, -0.8, 0.0, 1.0,             // lower-right
      -0.8, -0.8, 0.0, 1.0]
    controlPointsBufferQuad = device.makeBuffer(bytes: controlPointPositionsQuad, length: 16 * MemoryLayout<Float>.size, options: controlPointsBufferOptions)
    controlPointsBufferQuad?.label = "Control Points Quad"
    // More sophisticated tessellation passes might have additional buffers for per-patch user data
  }
  
  // MARK: Compute/Render methods
  func computeTessellationFactors(with commandBuffer: MTLCommandBuffer) {
    // Create a compute command encoder
    let computeCommandEncoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
    computeCommandEncoder.label = "Compute Command Encoder"
    // Begin encoding compute commands
    computeCommandEncoder.pushDebugGroup("Compute Tessellation Factors")
    // Set the correct compute pipeline
    if patchType == .triangle {
      computeCommandEncoder.setComputePipelineState(computePipelineTriangle!)
    }
    else if patchType == .quad {
      computeCommandEncoder.setComputePipelineState(computePipelineQuad!)
    }
    
    // Bind the user-selected edge and inside factor values to the compute kernel
    computeCommandEncoder.setBytes(edgeFactor, length: MemoryLayout<Float>.size, at: 0)
    computeCommandEncoder.setBytes(insideFactor, length: MemoryLayout<Float>.size, at: 1)
    // Bind the tessellation factors buffer to the compute kernel
    computeCommandEncoder.setBuffer(tessellationFactorsBuffer, offset: 0, at: 2)
    // Dispatch threadgroups
    computeCommandEncoder.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    // All compute commands have been encoded
    computeCommandEncoder.popDebugGroup()
    computeCommandEncoder.endEncoding()
  }
  
  func tessellateAndRender(in view: MTKView, with commandBuffer: MTLCommandBuffer) {
    // Obtain a renderPassDescriptor generated from the view's drawable
    let renderPassDescriptor: MTLRenderPassDescriptor? = view.currentRenderPassDescriptor
    
    
    // If the renderPassDescriptor is valid, begin the commands to render into its drawable
    if renderPassDescriptor != nil {
      /*
      //renderPassDescriptor?.colorAttachments[0].texture = .texture // assign passed texture
      renderPassDescriptor?.colorAttachments[0].texture = view.currentDrawable?.texture
      renderPassDescriptor?.colorAttachments[0].loadAction = .clear // set the texture to the clear color before doing any drawing
      renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0) // set clear color to green
      //renderPassDescriptor?.colorAttachments[0].storeAction = .multisampleResolve
      //renderPassDescriptor?.colorAttachments[0].storeAction = .unknown
      //renderPassDescriptor?.colorAttachments[0].texture = view.currentDrawable?.texture
      //renderPassDescriptor?.colorAttachments[0].texture = view.multisampleColorTexture
 */
      
      // Create a render command encoder
      let renderCommandEncoder: MTLRenderCommandEncoder? = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
      renderCommandEncoder?.label = "Render Command Encoder"
      // Begin encoding render commands, including commands for the tessellator
      renderCommandEncoder?.pushDebugGroup("Tessellate and Render")
      // Set the correct render pipeline and bind the correct control points buffer
      if patchType == .triangle {
        renderCommandEncoder?.setRenderPipelineState(renderPipelineTriangle!)
        renderCommandEncoder?.setVertexBuffer(controlPointsBufferTriangle, offset: 0, at: 0)
      }
      else if patchType == .quad {
        renderCommandEncoder?.setRenderPipelineState(renderPipelineQuad!)
        renderCommandEncoder?.setVertexBuffer(controlPointsBufferQuad, offset: 0, at: 0)
      }
      
      // Enable/Disable wireframe mode
      if isWireframe {
        renderCommandEncoder?.setTriangleFillMode(.lines)
      }
      // Encode tessellation-specific commands
      renderCommandEncoder?.setTessellationFactorBuffer(tessellationFactorsBuffer, offset: 0, instanceStride: 0)
      let patchControlPoints: Int = (patchType == .triangle) ? 3 : 4
      //renderCommandEncoder.drawPatches(numberOfPatchControlPoints: 3, patchStart: 0, patchCount: 1, patchIndexBuffer: nil, patchIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)
      renderCommandEncoder?.drawPatches(numberOfPatchControlPoints: patchControlPoints, patchStart: 0, patchCount: 1, patchIndexBuffer: nil, patchIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)
      
      
      
      
      // All render commands have been encoded
      renderCommandEncoder?.popDebugGroup()
      renderCommandEncoder?.endEncoding()
      // Schedule a present once the drawable has been completely rendered to
      commandBuffer.present(view.currentDrawable!)
    }
  }
  
  // MARK: MTKView delegate methods
  // Called whenever view changes orientation or layout is changed
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  }
  
  // Called whenever the view needs to render
  func draw(in view: MTKView) {
    autoreleasepool {
      // Create a new command buffer for each tessellation pass
      let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
      
      commandBuffer?.label = "Tessellation Pass"
      
      self.computeTessellationFactors(with: commandBuffer!)
      
      self.tessellateAndRender(in: view, with: commandBuffer!)
      // Finalize tessellation pass and commit the command buffer to the GPU
      commandBuffer?.commit()
 
    }
  }
}
