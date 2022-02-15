/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPServices
import Foundation
import UIKit

public class QuickConnectView {
    
    private let HEADER_HEIGHT = 110.0
    private let HEADER_LABEL_HEIGHT = 60.0
    
    private let DESCRIPTION_TEXTVIEW_TOP_MARGIN = 30.0
    private let DESCRIPTION_TEXTVIEW_HEIGHT = 50.0
    
    private let CONNECTION_IMAGE_TOP_MARGIN = 10.0
    private let CONNECTION_IMAGE_HEIGHT = 70.0
    
    private let BUTTON_HOLDER_TOP_MARGIN = 30.0
    private let BUTTON_HOLDER_HEIGHT = 60.0
    
    private let ADOBE_LOGO_IMAGE_BOTTOM_MARGIN = -60.0
    private let ADOBE_LOGO_IMAGE_HEIGHT = 20.0
    
    private let CANCEL_BUTTON_TOP_MARGIN = 10
    private let CANCEL_BUTTON_HEIGHT = 45.0
    private let BUTTON_CORNER_RADIUS = 22.5
    
    private let BUTTON_FONT_SIZE = 17.0
    
    private let manager : QuickConnectManager

    
    init(manager : QuickConnectManager) {
         self.manager = manager
     }
    
    public func show() {
        guard let window = UIApplication.shared.assuranceGetKeyWindow() else {
            Log.warning(label: AssuranceConstants.LOG_TAG, "QuickConnect View unable to get the keyWindow, ")
            return
        }

        window.addSubview(baseView)
        NSLayoutConstraint.activate([
            baseView.leftAnchor.constraint(equalTo: window.leftAnchor),
            baseView.rightAnchor.constraint(equalTo: window.rightAnchor),
            baseView.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            baseView.topAnchor.constraint(equalTo: window.topAnchor)
        ])
        
        baseView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leftAnchor.constraint(equalTo: baseView.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: baseView.rightAnchor),
            headerView.heightAnchor.constraint(equalToConstant: HEADER_HEIGHT),
            headerView.topAnchor.constraint(equalTo: baseView.topAnchor)
        ])
        
        headerView.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            headerLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            headerLabel.heightAnchor.constraint(equalToConstant: HEADER_LABEL_HEIGHT),
            headerLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        baseView.addSubview(descriptionTextView)
        NSLayoutConstraint.activate([
            descriptionTextView.leftAnchor.constraint(equalTo: baseView.leftAnchor),
            descriptionTextView.rightAnchor.constraint(equalTo: baseView.rightAnchor),
            descriptionTextView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: HEADER_HEIGHT + DESCRIPTION_TEXTVIEW_TOP_MARGIN),
            descriptionTextView.heightAnchor.constraint(equalToConstant: DESCRIPTION_TEXTVIEW_HEIGHT)
        ])
        
        baseView.addSubview(connectionImageView)
        NSLayoutConstraint.activate([
            connectionImageView.leftAnchor.constraint(equalTo: baseView.leftAnchor),
            connectionImageView.rightAnchor.constraint(equalTo: baseView.rightAnchor),
            connectionImageView.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: CONNECTION_IMAGE_TOP_MARGIN),
            connectionImageView.heightAnchor.constraint(equalToConstant: CONNECTION_IMAGE_HEIGHT)
        ])
        
        baseView.addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor, constant: 40.0),
            buttonStackView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor, constant: -40.0),
            buttonStackView.topAnchor.constraint(equalTo: connectionImageView.bottomAnchor, constant: BUTTON_HOLDER_TOP_MARGIN),
            buttonStackView.heightAnchor.constraint(equalToConstant: BUTTON_HOLDER_HEIGHT)
        ])
        
        buttonStackView.addArrangedSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.heightAnchor.constraint(equalToConstant: CANCEL_BUTTON_HEIGHT)
        ])
        

        buttonStackView.addArrangedSubview(connectButton)
        NSLayoutConstraint.activate([
            connectButton.heightAnchor.constraint(equalToConstant: CANCEL_BUTTON_HEIGHT)
        ])
        initialState()
        
        baseView.addSubview(adobeLogo)
        NSLayoutConstraint.activate([
            adobeLogo.leftAnchor.constraint(equalTo: baseView.leftAnchor),
            adobeLogo.rightAnchor.constraint(equalTo: baseView.rightAnchor),
            adobeLogo.bottomAnchor.constraint(equalTo: baseView.bottomAnchor, constant: ADOBE_LOGO_IMAGE_BOTTOM_MARGIN),
            adobeLogo.heightAnchor.constraint(equalToConstant: ADOBE_LOGO_IMAGE_HEIGHT)
        ])
        
        self.baseView.frame.origin.y = window.frame.size.height
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: { [] in
            self.baseView.frame.origin.y = 0
            self.baseView.backgroundColor = UIColor(red: 47.0/256.0, green: 47.0/256.0, blue: 47.0/256.0, alpha: 1)
        }, completion: nil)
            
    }
    
    @objc func cancelClicked(_ sender: AnyObject?) {
        dismiss()
     }
    
    @objc func connectClicked(_ sender: AnyObject?) {
        waitingState()
        manager.createDevice()
     }
        
        
    lazy private var baseView : UIView = {
        let view = UIView()
        view.accessibilityLabel = "AssuranceQuickConnectBaseView"
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy private var headerView : UIView = {
        let view = UIView()
        view.accessibilityLabel = "AssuranceQuickConnectHeaderView"
        view.backgroundColor = UIColor(red: 37.0/256.0, green: 37.0/256.0, blue: 37.0/256.0, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy private var headerLabel : UILabel = {
        let label = UILabel()
        label.accessibilityLabel = "AssuranceQuickConnectHeaderLabel"
        label.backgroundColor = .clear
        label.textColor = .white
        label.text = "Assurance"
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica-Bold", size: 30.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var descriptionTextView : UITextView = {
        let textView = UITextView()
        textView.accessibilityLabel = "AssuranceQuickConnectDescriptionTextView"
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.text = "Confirm connection by visiting your session's connection detail screen"
        textView.textAlignment = .center
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        textView.font = UIFont(name: "Helvetica", size: 16.0)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    lazy private var connectionImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(data: Data(bytes: connectionImage.content, count: connectionImage.content.count))
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityLabel = "AssuranceQuickConnectConnectionImageView"
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var adobeLogo : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(data: Data(bytes: adobelogo.content, count: adobelogo.content.count))
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityLabel = "AssuranceQuickConnectAdobeLogo"
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var buttonStackView : UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = .clear
        stackView.spacing = 15.0
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy private var cancelButton : UIButton = {
        let button = UIButton()
        button.contentMode = .scaleAspectFit
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = BUTTON_CORNER_RADIUS
        button.titleLabel?.font = UIFont(name: "Helvetica", size: BUTTON_FONT_SIZE)
        button.setTitle("Cancel", for: .normal)
        button.accessibilityLabel = "AssuranceQuickConnectButtonCancel"
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(self.cancelClicked(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy private var connectButton : UIButton = {
        let button = UIButton()
        button.contentMode = .scaleAspectFit
        button.backgroundColor = UIColor(red: 20.0/256.0, green: 115.0/256.0, blue: 230.0/256.0, alpha: 1)
        button.layer.cornerRadius = BUTTON_CORNER_RADIUS
        button.titleLabel?.font = UIFont(name: "Helvetica", size: BUTTON_FONT_SIZE)
        button.setTitle("Connect", for: .normal)
        button.accessibilityLabel = "AssuranceQuickConnectButtonConnect"
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(self.connectClicked(_:)), for: .touchUpInside)
        return button
    }()
    
    
    func initialState(){
        DispatchQueue.main.async {
            self.connectButton.setTitle("Connect", for: .normal)
            self.connectButton.backgroundColor = UIColor(red: 20.0/256.0, green: 115.0/256.0, blue: 230.0/256.0, alpha: 1)
            self.connectButton.isUserInteractionEnabled = true
        }
    }
    
    
    func waitingState() {
        DispatchQueue.main.async {
            self.connectButton.setTitle("Waiting...", for: .normal)
            self.connectButton.backgroundColor = UIColor(red: 67.0/256.0, green: 67.0/256.0, blue: 67.0/256.0, alpha: 1)
            self.connectButton.isUserInteractionEnabled = false
        }
    }
    
    func connectionSuccessfulState(){
        DispatchQueue.main.async {
            self.connectButton.setTitle("Connected", for: .normal)
            self.connectButton.backgroundColor = UIColor(red: 45.0/256.0, green: 157.0/256.0, blue: 120.0/256.0, alpha: 1)
            self.connectButton.isUserInteractionEnabled = false
        }
    }
    
//    func onSuccessfulDeviceRegistration() {
//          DispatchQueue.main.async {
//              UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
//                  self.labelRegisteringDevice.text = self.registerDeviceApproved
//              }, completion: {resut in
//                  self.labelDeviceApprovalStatus.isHidden = false
//                  self.labelDeviceApprovalHint.isHidden = false
//              })
//          }
//      }
      
      func onFailedDeviceRegistration() {
          DispatchQueue.main.async {
              
          }
      }
            
      func onSuccessfulApproval() {
              self.connectionSuccessfulState()
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
              self.dismiss()
          }
      }
      
      func onFailedApproval() {
          DispatchQueue.main.async {
              
          }
      }
    
    
    
    func dismiss() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.assuranceGetKeyWindow() else {
                return
            }
            
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: [.curveEaseInOut],
                           animations: { [self] in
                self.baseView.frame.origin.y = window.frame.size.height
            }, completion: { [self] _ in
                self.baseView.removeFromSuperview()
            })
        }
    
    }

}
