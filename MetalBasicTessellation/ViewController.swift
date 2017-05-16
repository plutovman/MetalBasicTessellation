//
//  ViewController.swift
//  MetalBasicTessellation
//

//

import UIKit
import MetalKit

class ViewController: UIViewController {
  
  @IBOutlet weak var mtkView: MTKView!
  @IBOutlet weak var edgeLabel: UILabel!
  @IBOutlet weak var insideLabel: UILabel!
  
  
  @IBAction func patchTypeSegmentedControlDidChange(_ sender: UISegmentedControl) {
    
    tessellationPipeline?.patchType = (sender.selectedSegmentIndex == 0) ? .triangle : .quad
    mtkView.draw()
  }
  
  @IBAction func wireframeDidChange(_ sender: UISwitch) {
    tessellationPipeline?.isWireframe = sender.isOn
    mtkView.draw()
  }
  
  @IBAction func edgeSliderDidChange(_ sender: UISlider) {
    edgeLabel.text = String(format: "%.1f", sender.value)
    tessellationPipeline?.edgeFactor = [sender.value]
    mtkView.draw()
  }
  
  @IBAction func insideSliderDidChange(_ sender: UISlider) {
    insideLabel.text = String(format: "%.1f", sender.value)
    tessellationPipeline?.insideFactor = [sender.value]
    mtkView.draw()
  }
  
  var tessellationPipeline: AAPLTessellationPipeline?

    override func viewDidLoad() {
      super.viewDidLoad()
      mtkView.isPaused = true
      mtkView.enableSetNeedsDisplay = true
      mtkView.sampleCount = 1 // no antialiasing
      //mtkView.sampleCount = 4 //antialiasing
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
