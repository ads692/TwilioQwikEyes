//
//  ViewController.swift
//  VideoQuickStart
//
//  Created by Kevin Whinnery on 12/16/15.
//  Copyright © 2015 Twilio. All rights reserved.
//

import UIKit

import TwilioConversationsClient
import TwilioCommon.TwilioAccessManager
import SnapKit
import SwiftyTimer

class ViewController: UIViewController {
  // MARK: View Controller Members
  
  // Configure access token manually for testing, if desired! Create one manually in the console 
  // at https://www.twilio.com/user/account/video/dev-tools/testing-tools
  var accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzlmZTNhM2ZlZTBiZWRmNTIzMTkzZmVkYTEwNDY0YWIzLTE0NzE3Mjg4NTgiLCJpc3MiOiJTSzlmZTNhM2ZlZTBiZWRmNTIzMTkzZmVkYTEwNDY0YWIzIiwic3ViIjoiQUM4Yzc4M2I4YWE5NGVkMTZiNzQ3MjkxZjNiOTAwZDc2NSIsImV4cCI6MTQ3MTczMjQ1OCwiZ3JhbnRzIjp7ImlkZW50aXR5IjoiQWRpdHlhIiwicnRjIjp7ImNvbmZpZ3VyYXRpb25fcHJvZmlsZV9zaWQiOiJWUzNhZTExZmQxYWFlYzY0ZWIxMGY3ZmFmYjkyOWNiNDYxIn19fQ.vEva5az0xZo7Xd0cXjNPTy57456uqKsodmhk8yxUjpE"
  
  // Configure remote URL to fetch token from
  var tokenUrl = "http://localhost:8000/token.php"
  
  // Video SDK components
  var accessManager: TwilioAccessManager?
  var client: TwilioConversationsClient?
  var localMedia: TWCLocalMedia?
  var camera: TWCCameraCapturer?
  var conversation: TWCConversation?
  var incomingInvite: TWCIncomingInvite?
  var outgoingInvite: TWCOutgoingInvite?
  
  // MARK: UI Element Outlets and handles
  var alertController: UIAlertController?
  @IBOutlet weak var remoteMediaView: UIView!
  @IBOutlet weak var localMediaView: UIView!
    var hangupButton: UIButton!
    var identityLabel: UIButton!
    var switchCameraButton: UIButton!
    var muteButton: UIButton!
  
  // Helper to determine if we're running on simulator or device
  struct Platform {
    static let isSimulator: Bool = {
      var isSim = false
      #if arch(i386) || arch(x86_64)
        isSim = true
      #endif
      return isSim
    }()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Configure access token either from server or manually
    // If the default wasn't changed, try fetching from server
    if self.accessToken == "TWILIO_ACCESS_TOKEN" {
      // If the token wasn't configured manually, try to fetch it from server
      let config = NSURLSessionConfiguration.defaultSessionConfiguration()
      let session = NSURLSession(configuration: config, delegate: nil, delegateQueue: nil)
      let url = NSURL(string: self.tokenUrl)
      let request  = NSMutableURLRequest(URL: url!)
      request.HTTPMethod = "GET"
      
      // Make HTTP request
      session.dataTaskWithRequest(request, completionHandler: { data, response, error in
        if (data != nil) {
          // Parse result JSON
          let json = JSON(data: data!)
          self.accessToken = json["token"].stringValue
          // Update UI and client on main thread
          dispatch_async(dispatch_get_main_queue()) {
            self.initializeClient()
          }
        } else {
          print("Error fetching token :\(error)")
        }
      }).resume()
    } else {
      // If token was manually set, initialize right away
      self.initializeClient()
    }
    
    // Style nav bar elements
    self.navigationController?.navigationBar.barTintColor = UIColor.redColor()
    self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    self.navigationController?.navigationBar.titleTextAttributes =
      [NSForegroundColorAttributeName : UIColor.whiteColor()]
    self.localMediaView.snp_makeConstraints {(make) -> Void in
        make.bottom.equalTo(self.remoteMediaView.snp_bottom).offset(-8)
    }
    setUpButtons()
    setUpVideoTapRecognizer()
  }
  
    func setUpButtons() {
        setUpHangupButton()
        setUpSwitchCameraButton()
        setUpMuteButton()
    }
    
    func setUpHangupButton() {
        self.hangupButton = UIButton()
        self.hangupButton.hidden = true
        self.hangupButton.alpha = 0.0
        self.view.addSubview(self.hangupButton)
        self.hangupButton.setImage(UIImage(named: "hangup"), forState: .Normal)
        self.hangupButton.addTarget(self, action: #selector(ViewController.hangup(_:)), forControlEvents: .TouchUpInside)
        self.hangupButton.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(60)
            make.width.equalTo(60)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop).offset(-8)
            make.centerX.equalTo(self.view.snp_centerX)
        }
    }
    
    func setUpSwitchCameraButton() {
        self.switchCameraButton = UIButton()
        self.switchCameraButton.hidden = true
        self.switchCameraButton.alpha = 0.0
        self.view.addSubview(self.switchCameraButton)
        self.switchCameraButton.setImage(UIImage(named: "switch-camera"), forState: .Normal)
        self.switchCameraButton.addTarget(self, action: #selector(ViewController.switchCamera), forControlEvents: .TouchUpInside)
        self.switchCameraButton.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(60)
            make.width.equalTo(60)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop).offset(-8)
            make.left.equalTo(self.hangupButton.snp_right).offset(8)
        }
    }
    
    func switchCamera() {
        self.camera?.flipCamera()
    }
    
    func setUpMuteButton() {
        self.muteButton = UIButton()
        self.muteButton.hidden = true
        self.muteButton.alpha = 0.0
        self.view.addSubview(self.muteButton)
        self.muteButton.setImage(UIImage(named: "mute"), forState: .Normal)
        self.muteButton.addTarget(self, action: #selector(ViewController.toggleMute), forControlEvents: .TouchUpInside)
        self.muteButton.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(60)
            make.width.equalTo(60)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop).offset(-8)
            make.right.equalTo(self.hangupButton.snp_left).offset(-8)
        }
    }
    
    func toggleMute() {
        if let local = self.localMedia {
            if local.microphoneMuted {
                local.microphoneMuted = false
                self.muteButton.setImage(UIImage(named: "mute"), forState: .Normal)
            } else {
                local.microphoneMuted = true
                self.muteButton.setImage(UIImage(named: "unmute"), forState: .Normal)
            }
        }
    }
    
    func showButtons() {
        self.hangupButton.hidden = false
        self.switchCameraButton.hidden = false
        self.muteButton.hidden = false
        UIView.animateWithDuration(0.7) { () -> Void in
            self.hangupButton.alpha = 1.0
            self.switchCameraButton.alpha = 1.0
            self.muteButton.alpha = 1.0
        }
    }
    
    func hideButtons() {
        UIView.animateWithDuration(0.7, animations: { () -> Void in
            self.hangupButton.alpha = 0.0
            self.switchCameraButton.alpha = 0.0
            self.muteButton.alpha = 0.0
        }) { (completed) -> Void in
            self.hangupButton.hidden = true
            self.switchCameraButton.hidden = true
            self.muteButton.hidden = true
        }
    }
    
    func setUpVideoTapRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.remoteMediaViewTapped))
        self.remoteMediaView.addGestureRecognizer(tap)
        self.remoteMediaView.userInteractionEnabled = true
    }
    
    func remoteMediaViewTapped() {
        showButtons()
        NSTimer.after(6.seconds) { () -> Void in
            self.hideButtons()
        }
    }

    
    
  // Once access token is set, initialize the Conversations SDK and display the identity of the
  // current user
  func initializeClient() {
    // Set up Twilio Conversations client
    self.accessManager = TwilioAccessManager(token:self.accessToken, delegate:self);
    self.client = TwilioConversationsClient(accessManager: self.accessManager!, delegate: self);
    self.client?.listen();
    
    self.startPreview()

    self.navigationItem.prompt = self.client?.identity
  }

  func startPreview() {
    // Setup local media preview
    self.localMedia = TWCLocalMedia(delegate: self)
    self.camera = self.localMedia?.addCameraTrack()

    if((self.camera) != nil && Platform.isSimulator != true) {
      self.camera!.videoTrack?.attach(self.localMediaView)
      self.camera!.videoTrack?.delegate = self;

      // Start the preview.
      self.camera!.startPreview();
      self.localMediaView!.addSubview((self.camera!.previewView)!)
      self.camera!.previewView?.frame = self.localMediaView!.bounds
      self.camera!.previewView?.contentMode = .ScaleAspectFit
      self.camera!.previewView?.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    }
  }

  // MARK: UI Controls
  @IBAction func invite(sender: AnyObject) {
    self.alertController = UIAlertController(title: "Invite User",
      message: "Enter the identity of the user you'd like to call.",
      preferredStyle: UIAlertControllerStyle.Alert)
    
    self.alertController?.addTextFieldWithConfigurationHandler({ textField in
      textField.placeholder = "SomeIdentity"
    })
    
    let action: UIAlertAction = UIAlertAction(title: "invite",
        style: UIAlertActionStyle.Default) { action in
      let invitee = self.alertController?.textFields!.first?.text!
      self.outgoingInvite = self.client?.inviteToConversation(invitee!, localMedia:self.localMedia!)
          { conversation, err in
        if err == nil {
          conversation!.delegate = self
          self.conversation = conversation
        } else {
          print("error creating conversation")
          print(err)
        }
      }
    }
    
    self.alertController?.addAction(action)
    self.presentViewController(self.alertController!, animated: true, completion: nil)
  }
  
  @IBAction func hangup(sender: AnyObject) {
    print("disconnect")
    self.conversation?.disconnect()
  }
}

// MARK: TWCLocalMediaDelegate
extension ViewController: TWCLocalMediaDelegate {
  func localMedia(media: TWCLocalMedia, didAddVideoTrack videoTrack: TWCVideoTrack) {
    print("added media track")
  }
}

// MARK: TWCVideoTrackDelegate
extension ViewController: TWCVideoTrackDelegate {
  func videoTrack(track: TWCVideoTrack, dimensionsDidChange dimensions: CMVideoDimensions) {
    print("video dimensions changed")
  }
}

// MARK: TwilioAccessManagerDelegate
extension ViewController: TwilioAccessManagerDelegate {
  func accessManagerTokenExpired(accessManager: TwilioAccessManager!) {
    print("access token has expired")
  }
  
  func accessManager(accessManager: TwilioAccessManager!, error: NSError!) {
    print("Access manager error:")
    print(error)
  }
}

// MARK: TwilioConversationsClientDelegate
extension ViewController: TwilioConversationsClientDelegate {
  func conversationsClient(conversationsClient: TwilioConversationsClient,
      didFailToStartListeningWithError error: NSError) {
    print("failed to start listening:")
    print(error)
  }
  
  // Automatically accept any invitation
  func conversationsClient(conversationsClient: TwilioConversationsClient,
      didReceiveInvite invite: TWCIncomingInvite) {
    print(invite.from)
    invite.acceptWithLocalMedia(self.localMedia!) { conversation, error in
      self.conversation = conversation
      self.conversation!.delegate = self
      
      self.showButtons()
      NSTimer.after(4.seconds, { () -> Void in
        self.hideButtons()
      })
    }
  }
}

// MARK: TWCConversationDelegate
extension ViewController: TWCConversationDelegate {
  func conversation(conversation: TWCConversation,
      didConnectParticipant participant: TWCParticipant) {
    self.navigationItem.title = participant.identity
    participant.delegate = self
  }
  
  func conversation(conversation: TWCConversation,
      didDisconnectParticipant participant: TWCParticipant) {
    self.navigationItem.title = "participant left"
  }
  
  func conversationEnded(conversation: TWCConversation) {
    self.navigationItem.title = "no call connected"
    self.hideButtons()

    // Restart the preview.
    self.startPreview()
  }
}

// MARK: TWCParticipantDelegate
extension ViewController: TWCParticipantDelegate {
  func participant(participant: TWCParticipant, addedVideoTrack videoTrack: TWCVideoTrack) {
    videoTrack.attach(self.remoteMediaView)
  }
}

