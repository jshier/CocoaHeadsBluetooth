//
//  PeripheralViewController.swift
//  CocoaHeadsBluetooth
//
//  Created by Jon Shier on 3/19/15.
//  Copyright (c) 2015 Jon Shier. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

class PeripheralViewController: UIViewController, CBPeripheralDelegate, UITableViewDataSource {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var UUIDLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var peripheral: CBPeripheral!
    
    override func viewDidLoad() {
        tableView.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        println("Peripheral: \(peripheral)")
        
        nameLabel.text = peripheral.name ?? "No Name"
        UUIDLabel.text = peripheral.identifier.UUIDString
        RSSILabel.text = "\(peripheral.RSSI)"
        
        peripheral.delegate = self
        peripheral.readRSSI()
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("Did discover services.")
        if let error = error {
            println(error)
        }
        else {
            println("\(peripheral.services)")
            tableView.reloadData()
        }
        
        // Uncomment the below code if you want to look for a characteristic named Battery. Found on a FitBit Flex, for example.
//        for service in peripheral.services {
//            if service.UUID.description == "Battery" {
//                peripheral.discoverCharacteristics(nil, forService: (service as CBService))            }
//        }
    }
    
    // Uncomment the below to handle characteristic discovery, like say, for the battery of a FitBit Flex.
//    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
//        let characteristic = service.characteristics.first as CBCharacteristic
//        println("\(characteristic)")
//        peripheral.readValueForCharacteristic(characteristic)
//        peripheral.setNotifyValue(true, forCharacteristic: characteristic) 
//    }
    
    // Uncomment the below if you want to recieve updates for a characteristic, like say, the battery for a FitBit Flex.
//    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
//        if let error = error {
//            println("Failed to updated value for characteristic with error: \(error)")
//        }
//        else {
//            println("Battery level: \(characteristic)")
//        }
//    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral!, error: NSError!) {
        println("Did update RSSI.")
        if let error = error {
            println("Error getting RSSI: \(error)")
            RSSILabel.text = "Error getting RSSI."
        }
        else {
            RSSILabel.text = "\(peripheral.RSSI)"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServiceCell", forIndexPath: indexPath) as UITableViewCell
        let service = peripheral.services[indexPath.row] as CBService
        println("Service UUID Description: \(service.UUID.description)")
        cell.textLabel?.text = service.UUID.description
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheral.services?.count ?? 0
    }
}
