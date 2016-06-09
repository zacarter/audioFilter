//
//  AudioFilterViewController.swift
//

import UIKit

class AudioFilterViewController: UIViewController {
  @IBOutlet weak var filterLabel: UILabel!
  @IBOutlet weak var swipeToChangeLabel: UILabel!
  @IBOutlet weak var nextFilterArrow: UIImageView!
  @IBOutlet weak var prevFilterArrow: UIImageView!
  @IBOutlet weak var cancelButton: UIButton!
  
  var context = CIContext(options:[kCIContextWorkingColorSpace: NSNull()])
  
  let audioFilterTitleArray: [String] = ["NONE", "LOW PITCH", "HIGH PITCH", "ROBOT"]
  var selectedAudioFilterIndex = 0
  var audioFilterChannel: AEPlaythroughChannel?
  
  var movieBuilder: MovieBuilder?
  
  var previousFilterIndex : Int?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.transitionToFilterLabel(self.audioFilterTitleArray[self.selectedAudioFilterIndex])
    // Do any additional setup after loading the view.
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    startAudioFilterPreview()
    showSwipeInstructions()
    previousFilterIndex = selectedAudioFilterIndex
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    stopAudioFilterPreview()
    SEGAnalytics.sharedAnalytics().track("Selected Audio Filter", properties: ["name": self.audioFilterTitleArray[self.selectedAudioFilterIndex]])
  }
  
  // MARK: - Actions
  
  @IBAction func swipeRight(sender: AnyObject) {
    self.selectedAudioFilterIndex--
    if self.selectedAudioFilterIndex < 0 {
      self.selectedAudioFilterIndex = self.audioFilterTitleArray.count-1
    }
    self.applyNewlySelectedAudioFilter()
  }
  
  @IBAction func swipeLeft(sender: AnyObject) {
    self.selectedAudioFilterIndex++
    if self.selectedAudioFilterIndex >= self.audioFilterTitleArray.count {
      self.selectedAudioFilterIndex = 0
    }
    self.applyNewlySelectedAudioFilter()
  }
  
  func applyNewlySelectedAudioFilter() {
    self.transitionToFilterLabel(self.audioFilterTitleArray[self.selectedAudioFilterIndex])
    self.showSwipeInstructions()
    SEGAnalytics.sharedAnalytics().track("Preview Audio Filter", properties: ["name": self.audioFilterTitleArray[self.selectedAudioFilterIndex]])
    applyAudioFilter()
  }
  
  func applyAudioFilter() {
    if let movieBuilder = movieBuilder {
      let currentFilterArray: [AEAudioUnitFilter] = movieBuilder.audioController!.inputFilters() as [AEAudioUnitFilter]
      switch self.selectedAudioFilterIndex {
      case 0:
        if movieBuilder.delayFilter != nil && contains(currentFilterArray, movieBuilder.delayFilter!) {
          movieBuilder.removeRobotVoiceFilter()
        }
        movieBuilder.audioController!.removeInputFilter(movieBuilder.audioFilter)
        if (audioFilterChannel != nil) {
          movieBuilder.audioController?.removeInputReceiver(audioFilterChannel)
          movieBuilder.audioController?.removeChannels([audioFilterChannel!])
        }
        break
      case 1:
        if movieBuilder.delayFilter != nil && contains(currentFilterArray, movieBuilder.delayFilter!) {
          movieBuilder.removeRobotVoiceFilter()
        }
        if movieBuilder.audioFilter != nil && !contains(currentFilterArray, movieBuilder.audioFilter!) {
          movieBuilder.audioController!.addInputFilter(movieBuilder.audioFilter)
        }
        let pitch: Float32 = -700 // low pitch
        AudioUnitSetParameter(movieBuilder.audioFilter!.audioUnit,AudioUnitParameterID(kNewTimePitchParam_Pitch), 0, AudioUnitParameterID(kAudioUnitScope_Global), pitch, 0)
        movieBuilder.audioController?.addInputReceiver(audioFilterChannel)
        movieBuilder.audioController?.addChannels([audioFilterChannel!])
        break
      case 2:
        if movieBuilder.delayFilter != nil && contains(currentFilterArray, movieBuilder.delayFilter!) {
          movieBuilder.removeRobotVoiceFilter()
        }
        if movieBuilder.audioFilter != nil && !contains(currentFilterArray, movieBuilder.audioFilter!) {
          movieBuilder.audioController!.addInputFilter(movieBuilder.audioFilter)
        }
        let pitch: Float32 = 1000 // high pitch voice
        AudioUnitSetParameter(movieBuilder.audioFilter!.audioUnit,AudioUnitParameterID(kNewTimePitchParam_Pitch), 0, AudioUnitParameterID(kAudioUnitScope_Global), pitch, 0)
        movieBuilder.audioController?.addInputReceiver(audioFilterChannel)
        movieBuilder.audioController?.addChannels([audioFilterChannel!])
        break
      case 3:
        movieBuilder.audioController!.removeInputFilter(movieBuilder.audioFilter)
        movieBuilder.setupRobotVoiceFilter()
        movieBuilder.audioController?.addInputReceiver(audioFilterChannel)
        movieBuilder.audioController?.addChannels([audioFilterChannel!])
        break
      default:
        break
      }
    }
  }
  
  func transitionToFilterLabel(text: String!){
    // Add transition (must be called after label has been displayed)
    var animation: CATransition = CATransition()
    animation.duration = 1.0
    animation.type = kCATransitionFade
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    self.filterLabel.layer.addAnimation(animation, forKey:"changeTextTransition")
    
    self.filterLabel.text = text
  }
  
  func startAudioFilterPreview() {
    if let movieBuilder = movieBuilder {
      audioFilterChannel = AEPlaythroughChannel(audioController:movieBuilder.audioController)
      if self.selectedAudioFilterIndex != 0 {
        movieBuilder.audioController?.addInputReceiver(audioFilterChannel)
        movieBuilder.audioController?.addChannels([audioFilterChannel!])
      }
      
      var error: NSError?
      movieBuilder.audioController?.start(&error)
    }
  }
  
  func stopAudioFilterPreview() {
    if let movieBuilder = movieBuilder {
      if (audioFilterChannel != nil) {
        movieBuilder.audioController?.removeInputReceiver(audioFilterChannel)
        movieBuilder.audioController?.removeChannels([audioFilterChannel!])
      }
    }
  }

  func showSwipeInstructions() {
    UIView.animateWithDuration(0.3, animations: { () -> Void in
      self.nextFilterArrow.alpha = 1
      self.prevFilterArrow.alpha = 1
      }) { (completed) -> Void in
        var time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), {
          UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.nextFilterArrow.alpha = 0
            self.prevFilterArrow.alpha = 0
          })
        })
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let button = sender as UIButton
    button.bounceElastically()
    if button == cancelButton {
      selectedAudioFilterIndex = previousFilterIndex!
      applyAudioFilter()
      filterLabel.text = self.audioFilterTitleArray[self.selectedAudioFilterIndex]
    }
  }
}