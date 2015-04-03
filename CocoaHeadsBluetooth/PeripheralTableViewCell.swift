//
//  PeripheralTableViewCell.swift
//  CocoaHeadsBluetooth
//
//  Created by Jon Shier on 4/3/15.
//  Copyright (c) 2015 Jon Shier. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var UUIDLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var connectableLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    
    func setupWithPeripheral(peripheral: Peripheral) {
        nameLabel.text = peripheral.name
        UUIDLabel.text = peripheral.UUID
        RSSILabel.text = peripheral.RSSI
        connectableLabel.text = peripheral.connectable
    }
}
