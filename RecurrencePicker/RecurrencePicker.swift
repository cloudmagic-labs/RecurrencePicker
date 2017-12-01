//
//  RecurrencePicker.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import UIKit
import EventKit
//import RRuleSwift

open class RecurrencePicker: UITableViewController {
    open var language: RecurrencePickerLanguage = .english {
        didSet {
            InternationalControl.shared.language = language
        }
    }
    open weak var delegate: RecurrencePickerDelegate?
    open var tintColor = UIColor.yellow
    open var calendar = Calendar.current
    open var occurrenceDate = Date()
    open var backgroundColor: UIColor?
    open var separatorColor: UIColor?
    open var supportedCustomRecurrenceFrequencies = Constant.frequencies
    open var customRecurrenceMaximumInterval = Constant.pickerMaxRowCount
	open var viewDidAppear = false
	open var interactionController: UIPercentDrivenInteractiveTransition?

    fileprivate var recurrenceRule: RecurrenceRule?
	var selectedIndexPath = IndexPath(row: 0, section: 0)
	var initialSelectedIndex = IndexPath(row: 0, section: 0)
    // MARK: - Initialization
    public convenience init(recurrenceRule: RecurrenceRule?) {
        self.init(style: .grouped)
        self.recurrenceRule = recurrenceRule
    }

    // MARK: - Life cycle
    open override func viewDidLoad()
	{
        super.viewDidLoad()
		navigationItem.title = LocalizedString("RecurrencePicker.navigation.title")
		NTCNotifyMeTableViewCell.registerCellForTableView(self.tableView)
		self.tableView.isHidden = true
		tableView.separatorStyle = .none
        
		self.backgroundColor = .clear
		self.view.backgroundColor = .clear
		self.tableView.backgroundColor = .clear
		self.navigationController?.isNavigationBarHidden = true
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
    }

	override open func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		if viewDidAppear == true && NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			self.tableView.isHidden = true
		}
	}

	open override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		if viewDidAppear == false {
			viewDidAppear = true
			commonInit()
			self.initialSelectedIndex = self.selectedIndexPath
			setUIForOrientation()
			self.fadeOut()
		}
	}

	override open func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		if viewDidAppear == true {
			self.tableView.isHidden = false
		}
	}

	fileprivate func fadeOut() {
		self.tableView.isHidden = true
		let transitionOptions: UIViewAnimationOptions = [.curveEaseIn]

		UIView.transition(with: self.tableView, duration: 0.5, options: transitionOptions, animations: {
			self.tableView.isHidden = false
		})
	}

	private func setUIForOrientation()
	{
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			// iPhone
			self.tableView.backgroundColor = UIColor.clear
			self.tableView.layer.cornerRadius = 0.0
		}else {
			self.tableView.backgroundColor = CMViewUtilities.shared().ipadCalFormSheetColor
			self.tableView.layer.cornerRadius = 5.0
		}
		self.tableView.reloadData()
		self.backgroundColor = UIColor.green
	}

	override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: nil, completion: {
			_ in
			self.setUIForOrientation()
		})
	}

    open override func didMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            // navigation is popped
            recurrencePickerDidPickRecurrence()
        }
    }
    
    // MARK: - Actions
    @objc func doneButtonTappedForParentVC() {
		self.recurrencePickerDidPickRecurrence()
    }
}

extension RecurrencePicker {
    // MARK: - Table view data source and delegate

	open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 121
		}
		return 20
	}

	open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 121))
		if section != 0 {
			headerView.frame = CGRect.zero
			return headerView
		}
		let label:UILabel = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		headerView.addSubview(label)
		label.backgroundColor = UIColor.clear;

		label.font = CMViewUtilities.shared().lightFont(25)
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			label.textColor = UIColor.white.withAlphaComponent(0.8)
		}else {
			label.textColor = UIColor.black.withAlphaComponent(0.8)
		}
		label.text = "Repeat"
        label.textAlignment = .left

		var hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-35-[label]-35-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["label":label]);
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-21-[label]-21-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["label":label]);
		}

		let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-68-[label]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["label":label]);

		NSLayoutConstraint.activate(hConstraint)
		NSLayoutConstraint.activate(vConstraint)
		return headerView;
	}


    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Constant.basicRecurrenceStrings().count
        } else {
            return 1
        }
    }

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
            return Constant.defaultRowHeight
        }
        return 70
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 1 ? recurrenceRuleText() : nil
    }

	override open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
	{
		let footer : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			footer.textLabel?.textColor = UIColor.white.withAlphaComponent(0.8)
			footer.textLabel?.font = CMViewUtilities.shared().regularFont(13)
		}else {
			footer.textLabel?.textColor = UIColor.black.withAlphaComponent(0.8)
			footer.textLabel?.font = CMViewUtilities.shared().regularFont(15)
		}
		if let footerText = recurrenceRuleText() {
			footer.textLabel?.text = "\n" + footerText
		}else {
			footer.textLabel?.text = ""
		}
		// patch for origin -x
		var frameOfFooter = footer.bounds
		frameOfFooter.origin.x  = NTCLayoutDetector().currentLayout().shouldUseIphoneUI ? -5 : -20
		footer.bounds = frameOfFooter

	}

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = NTCNotifyMeTableViewCell.reusableCellForTableView(tableView, indexPath: indexPath)
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			cell.backgroundColor = UIColor.white.withAlphaComponent(0.04)
		}else {
			cell.backgroundColor = UIColor(red: 216/255.0, green: 216/255.0, blue: 216/255.0, alpha: 0.2)
		}

		cell.accessoryType = .none
        cell.selectionStyle = .none

		if indexPath.section == 0 {
			cell.titleLabel.text = Constant.basicRecurrenceStrings()[indexPath.row]
		} else {
			cell.titleLabel.text = LocalizedString("RecurrencePicker.textLabel.custom")
		}

		if indexPath == selectedIndexPath {
			cell.tickIcon.isHidden = false
		} else {
			cell.tickIcon.isHidden = true
		}

		return cell
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let lastSelectedCell = tableView.cellForRow(at: selectedIndexPath) as? NTCNotifyMeTableViewCell
		if lastSelectedCell != nil {
			lastSelectedCell!.tickIcon.isHidden = true
		}

		let currentSelectedCell = tableView.cellForRow(at: indexPath) as! NTCNotifyMeTableViewCell


        currentSelectedCell.tickIcon.isHidden = false

        selectedIndexPath = indexPath

        if indexPath.section == 0 {
            updateRecurrenceRule(withSelectedIndexPath: indexPath)
            updateRecurrenceRuleText()
        } else {
            let customRecurrenceViewController = CustomRecurrenceViewController(style: .grouped)
            customRecurrenceViewController.occurrenceDate = occurrenceDate
            customRecurrenceViewController.tintColor = tintColor
            customRecurrenceViewController.backgroundColor = backgroundColor
            customRecurrenceViewController.separatorColor = separatorColor
            customRecurrenceViewController.supportedFrequencies = supportedCustomRecurrenceFrequencies
            customRecurrenceViewController.maximumInterval = customRecurrenceMaximumInterval
            customRecurrenceViewController.delegate = self

            var rule = recurrenceRule ?? RecurrenceRule.dailyRecurrence()
            let occurrenceDateComponents = calendar.dateComponents([.weekday, .day, .month], from: occurrenceDate)
            if rule.byweekday.count == 0 {
                let weekday = EKWeekday(rawValue: occurrenceDateComponents.weekday!)!
                rule.byweekday = [weekday]
            }
            if rule.bymonthday.count == 0 {
                let monthday = occurrenceDateComponents.day
                rule.bymonthday = [monthday!]
            }
            if rule.bymonth.count == 0 {
                let month = occurrenceDateComponents.month
                rule.bymonth = [month!]
            }
			customRecurrenceViewController.recurrenceRule = rule
			customRecurrenceViewController.initialStateRecurrenceRule = rule

            runInMainQueue {
				let customRecurrenceContainer = NTCRecurrencePickerViewController(tableController: customRecurrenceViewController)
				self.navigationController!.pushViewController(customRecurrenceContainer, animated: true)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension RecurrencePicker: CustomRecurrenceViewControllerDelegate {
	// MARK: - CustomRecurrenceViewController delegate
	func customRecurrenceViewController(_ controller: CustomRecurrenceViewController, didPickRecurrence recurrenceRule: RecurrenceRule) {
		self.recurrenceRule = recurrenceRule
		updateRecurrenceRuleText()
	}
}

extension RecurrencePicker {
    // MARK: - Helper
    fileprivate func commonInit() {

        updateSelectedIndexPath(withRule: recurrenceRule)
    }

    fileprivate func updateSelectedIndexPath(withRule recurrenceRule: RecurrenceRule?) {
        guard let recurrenceRule = recurrenceRule else {
            selectedIndexPath = IndexPath(row: 0, section: 0)
            return
        }
        if recurrenceRule.isDailyRecurrence() {
            selectedIndexPath = IndexPath(row: 1, section: 0)
        } else if recurrenceRule.isWeeklyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 2, section: 0)
        } else if recurrenceRule.isBiWeeklyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 3, section: 0)
        } else if recurrenceRule.isMonthlyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 4, section: 0)
        } else if recurrenceRule.isYearlyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 5, section: 0)
        } else if recurrenceRule.isWeekdayRecurrence() {
            selectedIndexPath = IndexPath(row: 6, section: 0)
        } else {
            selectedIndexPath = IndexPath(row: 0, section: 1)
        }
    }

    fileprivate func updateRecurrenceRule(withSelectedIndexPath indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }

        switch indexPath.row {
        case 0:
            recurrenceRule = nil
        case 1:
            recurrenceRule = RecurrenceRule.dailyRecurrence()
        case 2:
            let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: occurrenceDate))!
            recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
        case 3:
            let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: occurrenceDate))!
            recurrenceRule = RecurrenceRule.biWeeklyRecurrence(withWeekday: weekday)
        case 4:
            let monthday = calendar.component(.day, from: occurrenceDate)
            recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
        case 5:
            let month = calendar.component(.month, from: occurrenceDate)
            recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
        case 6:
            recurrenceRule = RecurrenceRule.weekdayRecurrence()
        default:
            break
        }
    }

    fileprivate func recurrenceRuleText() -> String? {
        return selectedIndexPath.section == 1 ? recurrenceRule?.toText(occurrenceDate: occurrenceDate) : nil
    }

    fileprivate func updateRecurrenceRuleText() {
        let footerView = tableView.footerView(forSection: 1)
        tableView.beginUpdates()
		if let footerText = recurrenceRuleText() {
			footerView?.textLabel?.text = "\n" + footerText
		}else {
			footerView?.textLabel?.text = ""
		}
		if footerView != nil {
			var frameOfFooter = footerView!.bounds
			frameOfFooter.origin.x  = NTCLayoutDetector().currentLayout().shouldUseIphoneUI ? -5 : -20
			footerView!.bounds = frameOfFooter
		}
        tableView.endUpdates()
        footerView?.setNeedsLayout()
    }

    fileprivate func recurrencePickerDidPickRecurrence() {
        if let rule = recurrenceRule {
            switch rule.frequency {
            case .daily:
                recurrenceRule?.byweekday.removeAll()
                recurrenceRule?.bymonthday.removeAll()
                recurrenceRule?.bymonth.removeAll()
            case .weekly:
                recurrenceRule?.byweekday = rule.byweekday.sorted(by: <)
                recurrenceRule?.bymonthday.removeAll()
                recurrenceRule?.bymonth.removeAll()
            case .monthly:
                recurrenceRule?.byweekday.removeAll()
                recurrenceRule?.bymonthday = rule.bymonthday.sorted(by: <)
                recurrenceRule?.bymonth.removeAll()
            case .yearly:
                recurrenceRule?.byweekday.removeAll()
                recurrenceRule?.bymonthday.removeAll()
                recurrenceRule?.bymonth = rule.bymonth.sorted(by: <)
            default:
                break
            }
        }
        recurrenceRule?.startDate = Date()

        delegate?.recurrencePicker(self, didPickRecurrence: recurrenceRule)
    }

	final func displayAlertToDiscardOrSaveChanges()
	{
		let cancel = NTAlert.Action.cancel()
		let ok = NTAlert.Action(title: "OK".localizedUppercaseString, action: {
			self.navigationController?.popViewController(animated: false)
		}, isDestructive: false, isCancel: false)
		NTAlert(title: "Discard Changes?", message: "Are you sure you want to discard the changes?", actions: [cancel, ok], showAsSheet: false).show(on: self)
	}

}
