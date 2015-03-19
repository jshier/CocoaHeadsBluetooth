//
//  ViewController.swift
//  CocoaHeadsBluetooth
//
//  Created by Jon Shier on 3/18/15.
//  Copyright (c) 2015 Jon Shier. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var manager: CBCentralManager!
    var isBluetoothEnabled = false
    var visiblePeripherals = Array<CBPeripheral>()
    var scanTimer: NSTimer?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func startScanning() {
        println("Started scanning.")
        manager.scanForPeripheralsWithServices(nil, options: nil)
        scanTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("stopScanning"), userInfo: nil, repeats: false)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        var printString: String
        switch central.state {
        case .PoweredOff:
            printString = "Bluetooth hardware powered off."
            isBluetoothEnabled = false
        case .PoweredOn:
            printString = "Bluetooth hardware powered on."
            isBluetoothEnabled = true
            startScanning()
        case .Resetting:
            printString = "Bluetooth hardware is resetting."
            isBluetoothEnabled = false
        case .Unauthorized:
            printString = "Bluetooth hardware is unauthorized."
            isBluetoothEnabled = false
        case .Unsupported:
            printString = "Bluetooth hardware is unsupported."
            isBluetoothEnabled = false
        case .Unknown:
            printString = "Bluetooth hardware state is unknown."
            isBluetoothEnabled = false
        }
        
        println("State updated to: \(printString)")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("Peripheral found.")
        visiblePeripherals.append(peripheral)
        tableView.reloadData()
    }
    
    func stopScanning() {
        println("Stopped scanning.")
        manager.stopScan()
        scanTimer?.invalidate()
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visiblePeripherals.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("PeripheralCell") as UITableViewCell
        cell.textLabel?.text = visiblePeripherals[indexPath.row].name
        
        return cell
    }
}

