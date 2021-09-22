//
//  ConnectionController.swift
//  SidePad
//
//  Created by Роман Гах on 24.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import UIKit
import CoreBluetooth
import os

public weak var GConnectionController: ConnectionController!

public class ConnectionController: UITableViewController {
    
//    var peripheralManager: CBPeripheralManager!
//    var connectCharacteristic: CBMutableCharacteristic?
//    var connectService: CBMutableService?
//    var connectCandidates: [ConnectCandidate] = [] // TODO: use list here

    public override func viewDidLoad() {
        GConnectionController = self
        BluetoothManager.shared.initPeripheral()
        super.viewDidLoad()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        // Don't keep advertising going while we're not showing.
        // peripheralManager.stopAdvertising()
        BluetoothManager.shared.stopAdvertising()

        super.viewWillDisappear(animated)
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        // return connectCandidates.count
        return BluetoothManager.shared.getCandidatesCount()
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CandidateCell", for: indexPath)
                    as! ConnectionControllerCell

        // cell.update(with: connectCandidates[indexPath.row])        
        cell.update(with: BluetoothManager.shared.getCandidateAt(indexPath.row))

        return cell
    }
    
    public func addCandidate(_ indexPath: IndexPath) -> Void {
        os_log("Add new candidate")
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.reloadData()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RemoteControllSegue" {
            let indexPath = tableView.indexPathForSelectedRow!
            let candidateName = tableView.cellForRow(at: indexPath)?.textLabel?.text ?? "<null>"

            // os_log("Select candidate %s, send accept message", candidateName)
            print("Select candidate %s, send accept message", candidateName)

            BluetoothManager.shared.sendData("Accept connect")
        }
    }
}
