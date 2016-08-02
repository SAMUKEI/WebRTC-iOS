
import AVFoundation
import UIKit

// Padding space for local video view with its parent.
let kLocalViewPadding:CGFloat = 20


class ViewController : UIViewController, UITextFieldDelegate {

    @IBOutlet var roomInput:UITextField!
    @IBOutlet var idField:UITextField!

    private var peer:Peer?
    private var isInitiater:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.roomInput.delegate = self
        self.roomInput.becomeFirstResponder()
        
        self.isInitiater = true
    }

    override func viewDidAppear(animate:Bool) {
        super.viewDidAppear(animate)
        
        if !self.isInitiater { return }
        self.peer?.disconnect()
        
        // full configurations.
        /*
         NSDictionary *config = @{@"host": @"0.peerjs.com",
         @"port": @(9000),
         @"key": @"peerjs",
         @"path": @"/",
         @"secure": @(NO),
         @"config": @{
         @"iceServers": @[
         @{@"url": @"stun:stun.l.google.com:19302", @"user": @"", @"password": @""}
         ]
         }};
         */
        
        let config = ["host": "yf-sunaba.tk", "path": "/", "key": "peerjs", "port": 9000, "secure": true,
                      "config":
                        [ "iceServers":
                            [[ "url": "turn:yf-sunaba.tk:3478", "user": "dev", "password":"iFqqn61sjs" ]]
                        ]
                      ]
        self.peer = Peer(config:config)
        guard let peer = self.peer else {
            return
        }
        peer.onOpen = { (id:String!) in
            NSLog("onOpen")
            self.idField.text = id
        }
        
        peer.onCall = { (sdp:RTCSessionDescription!, metadata: [NSObject: AnyObject]?) in
            NSLog("onCall")
            self.peerClient(self.peer, didReceiveOfferWithSdp:sdp)
        }
        
        peer.onError = { (error:NSError!) in
            NSLog("onError: %@", error)
            self.peerClient(self.peer, didError:error)
        }
        
        peer.onClose = { () in
            NSLog("onClose")
            self.resetUI()
        }
        
        peer.start({ () in
        })
    }
    
    func applicationWillResignActive(application:UIApplication!) {
        self.disconnect()
    }
    
    // MARK: - ARDAppClientDelegate
    
    func peerClient(client:Peer!, didReceiveOfferWithSdp sdp:RTCSessionDescription!) {
        NSLog("setup CaptureSession!")
        self.isInitiater = false
        self.roomInput.resignFirstResponder()
        self.roomInput.hidden = true
        
        client.answerWithSdp(sdp)
    }

    func peerClient(client:Peer!, didError error:NSError!) {
        self.showAlertWithMessage(String(format:"%@", error))
        self.disconnect()
    }

    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(textField:UITextField) {
        let dstId:String! = textField.text
        
        if dstId.characters.count == 0 {
            return
        }
        
        self.isInitiater = true
        textField.hidden = true
        self.peer?.callWithId(dstId, metadata: nil)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        // There is no other control that can take focus, so manually resign focus
        // when return (Join) is pressed to trigger |textFieldDidEndEditing|.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Private
    
    func disconnect() {
        self.resetUI()
        self.peer?.disconnect()
    }
    
    func showAlertWithMessage(message:String!) {
        let alertView:UIAlertView! = UIAlertView(title:"",
                                                 message:message,
                                                 delegate:nil,
                                                 cancelButtonTitle:"OK",
                                                 otherButtonTitles:"")
        alertView.show()
    }
    
    func resetUI() {
        self.roomInput.resignFirstResponder()
        self.roomInput.text = nil
        self.roomInput.hidden = false
    }
    
    
    @IBAction func finishCall(sender:AnyObject!) {
        self.disconnect()
    }
}