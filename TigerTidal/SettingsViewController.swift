//
//  SettingsViewController.swift
//  TigerTidal
//
//  Created by Sam Jordan on 12/22/14.
//  Copyright (c) 2014 Sam Jordan. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var firstnamefield: UITextField!
    @IBOutlet weak var lastnamefield: UITextField!
    @IBOutlet weak var classyearfield: UITextField!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var saveBtn: UIButton!
    
    var haveUserPref:Bool! = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //set up save button:
        saveBtn.addTarget(self, action: "saveAct:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //load saved data, toast info message if nil:
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let cy = defaults.objectForKey("classYear") as? String {
            //there is some saved data
            haveUserPref = true
            if let firstNameIsNotNill = defaults.objectForKey("firstName") as? String {
                self.firstnamefield.placeholder = firstNameIsNotNill
            }
 
            if let lastNameIsNotNill = defaults.objectForKey("lastName") as? String {
                self.lastnamefield.placeholder = lastNameIsNotNill
            }
 
            if let classYearIsNotNill = defaults.objectForKey("classYear") as? String {
                self.classyearfield.placeholder = classYearIsNotNill
            }
 
            if let anonSwitchIsNotNill = defaults.objectForKey("anon") as? Bool {
                self.anonymousSwitch.on = anonSwitchIsNotNill
            }
            saveBtn.enabled = true
        } else {
            //there is no saved data:
            toast("Please enter your information then tap 'Save'. The Class Year field is required.", title: "Instructions", btntext: "Ok")
            anonymousSwitch.on = false
            firstnamefield.placeholder = "Bob"
            lastnamefield.placeholder = "Smith"
            classyearfield.placeholder = "2016"
            saveBtn.enabled = false
        }
        
        //set delegates for real-time checking
        firstnamefield.delegate = self
        lastnamefield.delegate = self
        classyearfield.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveAct (sender: UIButton!) {
        println("doing save...")
        println("firstname: \(firstnamefield.text)")
        println("lastname: \(lastnamefield.text)")
        println("year: \(classyearfield.text)")
        println("anon: \(anonymousSwitch.on)")
        
        //now, check if input is valid:
        var inputOK = false
        if (haveUserPref == true) {
            if (!anonymousSwitch.on && (!firstnamefield.hasText() || !lastnamefield.hasText())) {
                inputOK = false
            }
            else {
                inputOK = true
            }
        }
        else if let intVal = classyearfield.text.toInt() {
            if ((firstnamefield.hasText() && lastnamefield.hasText()) || anonymousSwitch.on) {
                inputOK = true
            } else {
                inputOK = false
            }
        } else {
            inputOK = false
        }
        
        //inform user if there are errors in input:
        if(inputOK) {
            toast("Preferences saved", title:"Success!", btntext:"ok")
        }
        else {
            toast("Year must be a number, and Names can't be empty unless anonymous switch is on.", title:"Hold on!", btntext:"ok")
        }
        
        // actually save data:
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if (inputOK) {
            println("actually saving...")
            if (firstnamefield.hasText()) {
                defaults.setObject(self.firstnamefield.text, forKey:"firstName")
            }
            if (lastnamefield.hasText()) {
                defaults.setObject(self.lastnamefield.text, forKey:"lastName")
            }
            if (classyearfield.hasText()) {
                defaults.setObject(self.classyearfield.text, forKey:"classYear")
            }
            defaults.setObject(self.anonymousSwitch.on, forKey:"anon")
            defaults.synchronize()
        }
        
    }
    
    func toast(message:String, title:String, btntext:String) {
        println("toasting '\(message)'")
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: btntext, style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func viewTapped(sender : AnyObject) {
        //screen is tapped, dismiss keyboard
        self.view.endEditing(true)
    }
    
    //delegate, for real-time data checking (feedback for user)
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Find out what the text field will be after adding the current edit
        let cy = classyearfield.text
        
         if let intVal = cy.toInt(){
            // Text field converted to an Int
            if (firstnamefield.hasText() && lastnamefield.hasText()) {
                saveBtn.enabled = true
            }
            else {
                saveBtn.enabled = true
            }
        } else {
            // Text field is not an Int
            saveBtn.enabled = false
        }

        // Return true so the text field will be changed
        return true
    }
}
