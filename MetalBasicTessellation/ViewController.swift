//
//  ViewController.swift
//  MetalBasicTessellation
//

//

import UIKit
import MetalKit

class ViewController: UIViewController {
  
  @IBOutlet weak var mtkView: MTKView!
  
  var tessellationPipeline: AAPLTessellationPipeline?

    override func viewDidLoad() {
      super.viewDidLoad()
      mtkView.isPaused = true
      mtkView.enableSetNeedsDisplay = true
      mtkView.sampleCount = 1
      mtkView.depthStencilPixelFormat = .invalid
    }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tessellationPipeline = AAPLTessellationPipeline(mtkView: mtkView)
    mtkView.draw()
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
