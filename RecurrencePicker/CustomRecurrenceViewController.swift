//
//  CustomRecurrenceViewController.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import UIKit
import EventKit
//import RRuleSwift

internal protocol CustomRecurrenceViewControllerDelegate: class {
    func customRecurrenceViewController(_ controller: CustomRecurrenceViewController, didPickRecurrence recurrenceRule: RecurrenceRule)
}

internal class CustomRecurrenceViewController: UITableViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    internal weak var delegate: CustomRecurrenceViewControllerDelegate?
    internal var occurrenceDate: Date!
    internal var tintColor: UIColor!
    internal var recurrenceRule: RecurrenceRule!
    internal var backgroundColor: UIColor?
    internal var separatorColor: UIColor?
    internal var supportedFrequencies = Constant.frequencies
    internal var maximumInterval = Constant.pickerMaxRowCount

    fileprivate var isShowingPickerView = false
    fileprivate var pickerViewStyle: PickerViewCellStyle = .frequency

	open var viewDidAppear = false
	open var interactionController: UIPercentDrivenInteractiveTransition?
	let backButton = UIButton(type: .custom)

    fileprivate var isShowingFrequencyPicker: Bool {
        return isShowingPickerView && pickerViewStyle == .frequency
    }
    fileprivate var isShowingIntervalPicker: Bool {
        return isShowingPickerView && pickerViewStyle == .interval
    }
    fileprivate var frequencyCell: UITableViewCell? {
        return tableView.cellForRow(at: IndexPath(row: 0, section: 0))
    }
    fileprivate var intervalCell: UITableViewCell? {
        return isShowingFrequencyPicker ? tableView.cellForRow(at: IndexPath(row: 2, section: 0)) : tableView.cellForRow(at: IndexPath(row: 1, section: 0))
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = .clear
		self.tableView.backgroundColor = .clear
		self.navigationController?.isNavigationBarHidden = true
		self.navigationController!.delegate = self;
		self.tableView.separatorStyle = .singleLine
		self.setUpBackButton()
        
        let bundle = Bundle(identifier: "Teambition.RecurrencePicker") ?? Bundle.main
        tableView.register(UINib(nibName: "PickerViewCell", bundle: bundle), forCellReuseIdentifier: CellID.pickerViewCell)
        tableView.register(UINib(nibName: "MonthOrDaySelectorCell", bundle: bundle), forCellReuseIdentifier: CellID.monthOrDaySelectorCell)

        
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI == false {
			self.tableView.layer.cornerRadius = 10.0
			self.tableView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapBlurButton(_:)))
			tapGesture.cancelsTouchesInView = false
			self.navigationController!.view.addGestureRecognizer(tapGesture)
			tapGesture.delegate = self
		}

    }

	func tapBlurButton(_ sender: UITapGestureRecognizer) {
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI == false {
			self.view.fadeOut(duration: 0.10, alpha: 0.9) { (completed) in
				self.dismiss(animated: false, completion: nil)
			}
		}
	}

	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		if viewDidAppear == false {
			viewDidAppear = true
			let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
			let blurEffectView = UIVisualEffectView(effect: blurEffect)
			blurEffectView.frame = self.navigationController!.view.bounds
			blurEffectView.alpha = 0
			blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			self.navigationController?.view.insertSubview(blurEffectView, at: 0)

			blurEffectView.fadeIn(duration: 0.15, completion: { (completed) in
				print("displayed blurr view")
				self.navigationController?.view.addBackgroundGradientOnView()
			})
			commonInit()
		}
	}

	open override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI == false {
			self.tableView.frame = CGRect(x: (self.navigationController!.view.frame.size.width - 574 )/2, y: (self.navigationController!.view.frame.size.height - 645 )/2, width: 574, height: 645)
			self.backButton.isHidden = true
		}else{
			self.backButton.isHidden = false
		}
	}

	@objc func doneButtonTapped() {
		delegate?.customRecurrenceViewController(self, didPickRecurrence: recurrenceRule)

		self.view.fadeOut(duration: 0.10, alpha: 0.9) { (completed) in
			self.dismiss(animated: false) {
			}
		}
	}

	@objc func closeButtonTapped() {
		self.view.fadeOut(duration: 0.10, alpha: 0.9) { (completed) in
			self.dismiss(animated: false) {
			}
		}
	}
}

extension CustomRecurrenceViewController {
    // MARK: - Table view helper
    fileprivate func isPickerViewCell(at indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 && isShowingPickerView else {
            return false
        }
        return pickerViewStyle == .frequency ? indexPath.row == 1 : indexPath.row == 2
    }

    fileprivate func isSelectorViewCell(at indexPath: IndexPath) -> Bool {
        guard recurrenceRule.frequency == .monthly || recurrenceRule.frequency == .yearly else {
            return false
        }
        return indexPath == IndexPath(row: 0, section: 1)
    }

    fileprivate func unfoldPickerView() {
        switch pickerViewStyle {
        case .frequency:
            tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
        case .interval:
            tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        }
    }

    fileprivate func foldPickerView() {
        switch pickerViewStyle {
        case .frequency:
            tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
        case .interval:
            tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        }
    }

    fileprivate func updateSelectorSection(with newFrequency: RecurrenceFrequency) {
        tableView.beginUpdates()
        switch newFrequency {
        case .daily:
            if tableView.numberOfSections == 2 {
                tableView.deleteSections(IndexSet(integer: 1), with: .fade)
            }
        case .weekly, .monthly, .yearly:
            if tableView.numberOfSections == 1 {
                tableView.insertSections(IndexSet(integer: 1), with: .fade)
            } else {
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
        default:
            break
        }
        tableView.endUpdates()
    }

    fileprivate func unitStringForIntervalCell() -> String {
        if recurrenceRule.interval == 1 {
            return Constant.unitStrings()[recurrenceRule.frequency.number]
        }
        return String(recurrenceRule.interval) + " " + Constant.pluralUnitStrings()[recurrenceRule.frequency.number]
    }

    fileprivate func updateDetailTextColor() {
//        frequencyCell?.detailTextLabel?.textColor = isShowingFrequencyPicker ? tintColor : Constant.detailTextColor
//        intervalCell?.detailTextLabel?.textColor = isShowingIntervalPicker ? tintColor : Constant.detailTextColor
    }

    fileprivate func updateFrequencyCellText() {
        frequencyCell?.detailTextLabel?.text = Constant.frequencyStrings()[recurrenceRule.frequency.number]
    }

    fileprivate func updateIntervalCellText() {
        intervalCell?.detailTextLabel?.text = unitStringForIntervalCell()
    }

    fileprivate func updateRecurrenceRuleText() {
        let footerView = tableView.footerView(forSection: 0)

        tableView.beginUpdates()
		footerView?.textLabel?.text = "\n" + recurrenceRule.toText(occurrenceDate: occurrenceDate)!
        tableView.endUpdates()
        footerView?.setNeedsLayout()
    }
}

extension CustomRecurrenceViewController {
    // MARK: - Table view data source and delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if recurrenceRule.frequency == .daily {
            return 1
        }
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return isShowingPickerView ? 3 : 2
        } else {
            switch recurrenceRule.frequency {
            case .weekly: return Constant.weekdaySymbols().count
            case .monthly, .yearly: return 1
            default: return 0
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isPickerViewCell(at: indexPath) {
            return Constant.pickerViewCellHeight
        } else if isSelectorViewCell(at: indexPath) {
            let style: MonthOrDaySelectorStyle = recurrenceRule.frequency == .monthly ? .day : .month
            let itemHeight = GridSelectorLayout.itemSize(with: style, selectorViewWidth: tableView.frame.width).height
            let itemCount: CGFloat = style == .day ? 5 : 3
            return ceil(itemHeight * itemCount) + Constant.selectorVerticalPadding * CGFloat(2)
        }
        return Constant.defaultRowHeight
    }


	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		if section == 0 {
			return 110
		}
		return 0
	}

	 override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 60))
		if section != 0 {
			headerView.frame = CGRect.zero
			return headerView
		}

		return headerView;
	}

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
			return "\n" +  recurrenceRule.toText(occurrenceDate: occurrenceDate)!
        }
        return nil
    }

	override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
	{
		let footer : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			footer.textLabel?.textColor = UIColor.white.withAlphaComponent(0.8)
		}else {
			footer.textLabel?.textColor = UIColor.black.withAlphaComponent(0.8)
		}

		footer.textLabel?.font = CMViewUtilities.shared().lightFont(13)
		footer.textLabel?.text = "\n" + recurrenceRule.toText(occurrenceDate: occurrenceDate)!
	}
    

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.1)

    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.contentView.backgroundColor = .clear
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isPickerViewCell(at: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.pickerViewCell, for: indexPath) as! PickerViewCell
            cell.delegate = self

            cell.style = pickerViewStyle
            cell.frequency = recurrenceRule.frequency
            cell.interval = recurrenceRule.interval
            let supportedFrequencies: [RecurrenceFrequency] = {
                let frequencies = self.supportedFrequencies.filter { Constant.frequencies.contains($0) }.sorted { $0.number < $1.number }
                return frequencies.isEmpty ? Constant.frequencies : frequencies
            }()
            cell.supportedFrequencies = supportedFrequencies
            cell.maximumInterval = max(maximumInterval, 1)

            return cell
        } else if isSelectorViewCell(at: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.monthOrDaySelectorCell, for: indexPath) as! MonthOrDaySelectorCell
            cell.delegate = self

            cell.tintColor = tintColor
            cell.style = recurrenceRule.frequency == .monthly ? .day : .month
            cell.bymonthday = recurrenceRule.bymonthday
            cell.bymonth = recurrenceRule.bymonth

            return cell
        } else if indexPath.section == 0 {
            var cell = tableView.dequeueReusableCell(withIdentifier: CellID.customRecurrenceViewCell)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: CellID.customRecurrenceViewCell)
            }
            cell?.accessoryType = .none
            cell?.selectionStyle = .none
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.red
            cell?.selectedBackgroundView = backgroundView

            
			if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
				cell?.backgroundColor = UIColor.white.withAlphaComponent(0.04)
				cell!.textLabel!.textColor = UIColor.white.withAlphaComponent(0.8)
			}else{
				cell?.backgroundColor = UIColor.black.withAlphaComponent(0.04)
				cell!.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
			}

			cell!.textLabel!.font = CMViewUtilities.shared().regularFont(16)
			cell!.detailTextLabel!.font = CMViewUtilities.shared().regularFont(15)

			var detailTextColor = UIColor.black

			if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
				detailTextColor = UIColor.white
			}


            if indexPath.row == 0 {
                cell?.textLabel?.text = LocalizedString("CustomRecurrenceViewController.textLabel.frequency")
                cell?.detailTextLabel?.text = Constant.frequencyStrings()[recurrenceRule.frequency.number]

                cell?.detailTextLabel?.textColor = isShowingFrequencyPicker ? tintColor : detailTextColor
            } else {
                cell?.textLabel?.text = LocalizedString("CustomRecurrenceViewController.textLabel.interval")
                cell?.detailTextLabel?.text = unitStringForIntervalCell()
                cell?.detailTextLabel?.textColor = isShowingIntervalPicker ? tintColor : detailTextColor
                cell?.selectionStyle = .none

            }

            return cell!
        } else {

			let cell = NTCNotifyMeTableViewCell.reusableCellForTableView(tableView, indexPath: indexPath)
			if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
				cell.backgroundColor = UIColor.white.withAlphaComponent(0.04)
			}else{
				cell.backgroundColor = UIColor.black.withAlphaComponent(0.04)
			}

			cell.accessoryType = .none
			cell.titleLabel.text = Constant.weekdaySymbols()[indexPath.row]

			if recurrenceRule.byweekday.contains(Constant.weekdays[indexPath.row]) {
				cell.tickIcon.isHidden = false
			} else {
				cell.tickIcon.isHidden = true
			}

			return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isPickerViewCell(at: indexPath) else {
            return
        }
        guard !isSelectorViewCell(at: indexPath) else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                if isShowingFrequencyPicker {
                    tableView.beginUpdates()
                    isShowingPickerView = false
                    foldPickerView()
                    tableView.endUpdates()
                } else {
                    tableView.beginUpdates()
                    if isShowingIntervalPicker {
                        foldPickerView()
                    }
                    isShowingPickerView = true
                    pickerViewStyle = .frequency
                    unfoldPickerView()
                    tableView.endUpdates()
                }
                updateDetailTextColor()
            } else {
                if isShowingIntervalPicker {
                    tableView.beginUpdates()
                    isShowingPickerView = false
                    foldPickerView()
                    tableView.endUpdates()
                } else {
                    tableView.beginUpdates()
                    if isShowingFrequencyPicker {
                        foldPickerView()
                    }
                    isShowingPickerView = true
                    pickerViewStyle = .interval
                    unfoldPickerView()
                    tableView.endUpdates()
                }
                updateDetailTextColor()
            }
        } else if indexPath.section == 1 {
            if isShowingPickerView {
                tableView.beginUpdates()
                isShowingPickerView = false
                foldPickerView()
                tableView.endUpdates()
                updateDetailTextColor()
            }

            let weekday = Constant.weekdays[indexPath.row]
            if recurrenceRule.byweekday.contains(weekday) {
                if recurrenceRule.byweekday == [weekday] {
                    return
                }
                let index = recurrenceRule.byweekday.index(of: weekday)!
                recurrenceRule.byweekday.remove(at: index)
				(cell as! NTCNotifyMeTableViewCell).tickIcon.isHidden = true
                updateRecurrenceRuleText()
            } else {
                recurrenceRule.byweekday.append(weekday)
				(cell as! NTCNotifyMeTableViewCell).tickIcon.isHidden = false

                updateRecurrenceRuleText()
            }
        }
    }
}

extension CustomRecurrenceViewController {
    // MARK: - Helper

	fileprivate func setUpBackButton() {
		backButton.backgroundColor = .clear
		backButton.translatesAutoresizingMaskIntoConstraints = false
		backButton.isHidden = false
		backButton.addTarget(self, action: #selector(CustomRecurrenceViewController.closeButtonTapped), for: .touchUpInside)
		backButton.setImage(UIImage(named:"cal-back"), for: .normal)

		let leadingConstraint = NSLayoutConstraint(item: backButton, attribute: .leading, relatedBy: .equal, toItem: self.navigationController!.view, attribute: .leading, multiplier: 1, constant: 0)
		let topConstraint = NSLayoutConstraint(item: backButton, attribute: .top, relatedBy: .equal, toItem: self.navigationController!.view, attribute: .top, multiplier: 1, constant: 0)
		let width = NSLayoutConstraint(item: backButton, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 55)
		let height = NSLayoutConstraint(item: backButton, attribute: .height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 100)
		self.navigationController?.view.addSubview(backButton)
		self.navigationController!.view.addConstraints([leadingConstraint, topConstraint, width, height])
	}
	
    fileprivate func commonInit() {
        
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.08)
        
		NTCNotifyMeTableViewCell.registerCellForTableView(self.tableView)

		let doneButton = UIButton(type: .custom)
		doneButton.backgroundColor = .clear
		doneButton.addTarget(self, action: #selector(CustomRecurrenceViewController.doneButtonTapped), for: .touchUpInside)


		let font = CMViewUtilities.shared().regularFont(14)
		var textAttributes = [NSFontAttributeName: font, NSKernAttributeName: 1.0] as [String : Any]
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			textAttributes[NSForegroundColorAttributeName] = UIColor.white
		}else {
			textAttributes[NSForegroundColorAttributeName] = UIColor.black
		}
		doneButton.setAttributedTitle(NSAttributedString(string: "DONE", attributes: textAttributes), for: .normal)
		doneButton.translatesAutoresizingMaskIntoConstraints = false
		// for highlight state
		let highlightFont = CMViewUtilities.shared().regularFont(14)
		var highlightTextAttributes = [NSFontAttributeName: highlightFont, NSKernAttributeName: 1.0] as [String : Any]
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			highlightTextAttributes[NSForegroundColorAttributeName] = UIColor.white.withAlphaComponent(0.8)
		}else {
			highlightTextAttributes[NSForegroundColorAttributeName] = UIColor.black.withAlphaComponent(0.8)
		}
		doneButton.setAttributedTitle(NSAttributedString(string: "DONE", attributes: highlightTextAttributes), for: .highlighted)
		self.navigationController?.view.addSubview(doneButton)

		let leadingConstraint = NSLayoutConstraint(item: doneButton, attribute: .leading, relatedBy: .equal, toItem: self.tableView, attribute: .leading, multiplier: 1, constant: 0)
		let trailingConstraint = NSLayoutConstraint(item: doneButton, attribute: .trailing, relatedBy: .equal, toItem: self.tableView, attribute: .trailing, multiplier: 1, constant: 0)
		let bottomConstraint = NSLayoutConstraint(item: doneButton, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
		let height = NSLayoutConstraint(item: doneButton, attribute: .height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 60)

		self.navigationController?.view.addConstraints([leadingConstraint, trailingConstraint, bottomConstraint, height])

		var blur = UIVisualEffectView(effect: UIBlurEffect(style:
			UIBlurEffectStyle.dark))
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI == false {
			blur = UIVisualEffectView(effect: UIBlurEffect(style:
				UIBlurEffectStyle.dark))
		}
		blur.frame = doneButton.bounds
		blur.isUserInteractionEnabled = false //This allows touches to forward to the button.
		blur.alpha = 0.8
		blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		doneButton.insertSubview(blur, at: 0)

		self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
    }
}

extension CustomRecurrenceViewController: PickerViewCellDelegate {
    func pickerViewCell(_ cell: PickerViewCell, didSelectFrequency frequency: RecurrenceFrequency) {
        recurrenceRule.frequency = frequency

        updateFrequencyCellText()
        updateIntervalCellText()
        updateSelectorSection(with: frequency)
        updateRecurrenceRuleText()
    }

    func pickerViewCell(_ cell: PickerViewCell, didSelectInterval interval: Int) {
        recurrenceRule.interval = interval

        updateIntervalCellText()
        updateRecurrenceRuleText()
    }
}

extension CustomRecurrenceViewController: MonthOrDaySelectorCellDelegate {
    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didSelectMonthday monthday: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
            updateDetailTextColor()
        }
        recurrenceRule.bymonthday.append(monthday)
        updateRecurrenceRuleText()
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didDeselectMonthday monthday: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
            updateDetailTextColor()
        }
        if let index = recurrenceRule.bymonthday.index(of: monthday) {
            recurrenceRule.bymonthday.remove(at: index)
            updateRecurrenceRuleText()
        }
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, shouldDeselectMonthday monthday: Int) -> Bool {
        return recurrenceRule.bymonthday.count > 1
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didSelectMonth month: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
            updateDetailTextColor()
        }
        recurrenceRule.bymonth.append(month)
        updateRecurrenceRuleText()
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didDeselectMonth month: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
            updateDetailTextColor()
        }
        if let index = recurrenceRule.bymonth.index(of: month) {
            recurrenceRule.bymonth.remove(at: index)
            updateRecurrenceRuleText()
        }
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, shouldDeselectMonth month: Int) -> Bool {
        return recurrenceRule.bymonth.count > 1
    }
}

extension CustomRecurrenceViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in

            }) { (_) in
                let frequency = self.recurrenceRule.frequency
                if frequency == .monthly || frequency == .yearly {
                    if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? MonthOrDaySelectorCell {
                        cell.style = frequency == .monthly ? .day : .month
                    }
                }
        }
    }

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {


		let touchPoint = touch.location(in: self.navigationController!.view)

		if (self.tableView.frame.contains(touchPoint)) {
			return false
		}
		return true
	}

	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}

}
