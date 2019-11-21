//
//  ChatImageQualityTableViewController.swift
//  MEGA
//
//  Created by Haoran Li on 21/11/19.
//  Copyright © 2019 MEGA. All rights reserved.
//

import UIKit

enum ChatImageQuality {
    case auto
    case high
    case optimised
}


class ChatImageQualityTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let currentSeletedQuality = UserDefaults.standard.integer(forKey: "chatImageQuality")

        cell.accessoryView = UIImageView.init(image: #imageLiteral(resourceName: "red_checkmark"))
        cell.accessoryView?.isHidden = currentSeletedQuality != indexPath.row

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Automatic"
            cell.detailTextLabel?.text = "Send smaller size images through cellular networks and original size images through wifi"
            break
        case 1:
            cell.textLabel?.text = "High"
            cell.detailTextLabel?.text = "Send original size, increased quality images"
        case 2:
            cell.textLabel?.text = "Optimised"
            cell.detailTextLabel?.text = "Send smaller size images optimised for lower data consumption"
            
        default:
            return cell
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.set(indexPath.row, forKey: "chatImageQuality")
        tableView.reloadData()
    }
  

}
