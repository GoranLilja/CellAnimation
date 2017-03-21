//
//  ViewController.swift
//  CellAnimation
//
//  Created by Göran Lilja on 2017-03-21.
//  Copyright © 2017 Familjen Lilja. All rights reserved.
//

import UIKit

let animationDuration = TimeInterval(0.3)

class ViewController: UITableViewController {

    var cells = [UITableViewCell]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Clean up the UI
        // - Getting rid of the 1px line
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        // - Getting rid of empty cells
        tableView.tableFooterView = UIView()

        // Setting initial cells
        reset(self)
    }

    @IBAction func reset(_ sender: Any) {
        guard let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell") as? TextFieldCell
            else { return }

        // Add target to handle when the user taps `Done` on the virtual keyboard.
        textFieldCell.textField.addTarget(self, action: #selector(editingFinished(_:)), for: .editingDidEndOnExit)

        // Repopulate the cell array (i.e. get rid of the LabelCell, if present).
        cells = [UITableViewCell]()
        cells.append(textFieldCell)

        // Reload the table view
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = cells[indexPath.row]
        if let _ = cell as? LabelCell {
            return 100
        }
        if let cell = cell as? TextFieldCell {
            // Return the target height if animated, else the default height.
            return cell.isAnimating ? 100 : 47
        }

        // Unknown cell type, return the default cell height
        return 44
    }

    func editingFinished(_ textField: UITextField) {
        guard let text = textField.text else { return }

        // Get text size from the text field.
        let textSize = textField.intrinsicContentSize

        var originalFrame = textField.textRect(forBounds: textField.frame)
        // TODO: Figure out how to get this value dynamically.
        originalFrame.origin.y -= 2
        originalFrame.size = textSize

        // Prepare the target cell
        guard let labelCell = tableView.dequeueReusableCell(withIdentifier: "labelCell") as? LabelCell else { return }
        labelCell.label.text = text

        // Get the bounding rect of the text with width constraint based on the width of the destination's label.
        let boundingBox = text.boundingRect(
            with: CGSize(width: labelCell.label.frame.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 20)],
            context: nil)

        // Calculate the destination rect.
        var destinationRect = labelCell.label.bounds
        destinationRect.origin.x = labelCell.label.frame.maxX - boundingBox.width
        destinationRect.origin.y = labelCell.label.frame.minY

        // Let's create the temp label in order to animate it.
        let tempLabel = UILabel(frame: originalFrame)
        tempLabel.font = UIFont.systemFont(ofSize: 20)
        tempLabel.text = text
        tempLabel.textColor = textField.textColor
        tempLabel.frame.size.width = min(tempLabel.frame.size.width, labelCell.label.frame.size.width)

        // Let's add the label to the cell.
        guard let textFieldCell = cells.first as? TextFieldCell else { return }
        textFieldCell.addSubview(tempLabel)

        // Empty the textfield since we have the label to replace the text in it.
        textField.text = ""

        // Setting the `isAnimating` flag to true allows us to animate the height of the cell.
        // Ref: tableView(_, heightForRowAt:)
        textFieldCell.isAnimating = true

        // Allow the table view to update the height.
        // Ref: `layoutSubviews` of the `TextFielCell` class.
        tableView.beginUpdates()
        tableView.endUpdates()

        // Update the label (and now unnecessary text field).
        UIView.animate(withDuration: animationDuration, animations: {
            tempLabel.frame = destinationRect
            textField.alpha = 0
        }) { _ in
            // Remove the text field cell without animation, since we take care of that ourselves.
            // Important: The data source must be updated before the table view updates the UI.
            self.cells.remove(at: 0)
            self.tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.none)

            // Reset the cell for reuse at a later stage
            tempLabel.removeFromSuperview()
            textFieldCell.isAnimating = false
            textFieldCell.textField.alpha = 1

            // Add the label cell without animation, since we have already taken care of that.
            // Important: The data source must be updated before the table view updates the UI.
            self.cells.append(labelCell)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.none)
        }
    }
}
