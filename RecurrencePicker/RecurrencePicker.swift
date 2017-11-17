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

open class RecurrencePicker: UITableViewController, UIGestureRecognizerDelegate {
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
	let backButton = UIButton(type: .custom)

    fileprivate var isModal: Bool {
        return presentingViewController?.presentedViewController == self
            || (navigationController != nil && navigationController?.presentingViewController?.presentedViewController == navigationController && navigationController?.viewControllers.first == self)
            || tabBarController?.presentingViewController is UITabBarController
    }
    fileprivate var recurrenceRule: RecurrenceRule?
    fileprivate var selectedIndexPath = IndexPath(row: 0, section: 0)

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

		tableView.separatorStyle = .none
        
		self.backgroundColor = .clear
		self.view.backgroundColor = .clear
		self.tableView.backgroundColor = .clear
		self.navigationController?.isNavigationBarHidden = true
		self.navigationController!.delegate = self;
		self.setUpBackButton()
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)

		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI == false {
			self.tableView.layer.cornerRadius = 10.0
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapBlurButton(_:)))
            self.tableView.backgroundColor = CMViewUtilities.shared().ipadCalFormSheetColor
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

	open override func viewDidAppear(_ animated: Bool)
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
            self.tableView.reloadData()
            
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

    open override func didMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            // navigation is popped
            recurrencePickerDidPickRecurrence()
        }
    }
    
    // MARK: - Actions
    @objc func doneButtonTapped() {
		self.view.fadeOut(duration: 0.10, alpha: 0.9) { (completed) in
			self.dismiss(animated: false) {
				self.recurrencePickerDidPickRecurrence()
			}
		}
    }

    @objc func closeButtonTapped(_ sender: UIBarButtonItem) {
		self.view.fadeOut(duration: 0.10, alpha: 0.9) { (completed) in
			self.dismiss(animated: false) {
			}
		}
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
		let lastSelectedCell = tableView.cellForRow(at: selectedIndexPath) as! NTCNotifyMeTableViewCell
		let currentSelectedCell = tableView.cellForRow(at: indexPath) as! NTCNotifyMeTableViewCell

        lastSelectedCell.tickIcon.isHidden = true
        currentSelectedCell.tickIcon.isHidden = false

        selectedIndexPath = indexPath

        if indexPath.section == 0 {
            updateRecurrenceRule(withSelectedIndexPath: indexPath)
            updateRecurrenceRuleText()
            if !isModal {
                let _ = navigationController?.popViewController(animated: true)
            }
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

            runInMainQueue {
                let navController = UINavigationController(rootViewController: customRecurrenceViewController)
                navController.modalPresentationStyle = .overCurrentContext
                navController.isNavigationBarHidden = false
                self.navigationController!.present(navController, animated: false, completion: nil)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension RecurrencePicker {
    // MARK: - Helper
    fileprivate func commonInit() {

		let doneButton = UIButton(type: .custom)
		doneButton.backgroundColor = .clear
        doneButton.translatesAutoresizingMaskIntoConstraints = false
		doneButton.addTarget(self, action: #selector(RecurrencePicker.doneButtonTapped), for: .touchUpInside)

        var font = CMViewUtilities.shared().regularFont(16)
        if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
            font = CMViewUtilities.shared().regularFont(14)
        }
		var textAttributes = [NSFontAttributeName: font, NSKernAttributeName: 1.0] as [String : Any]
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			textAttributes[NSForegroundColorAttributeName] = UIColor.white.withAlphaComponent(0.8)
		}else {
			textAttributes[NSForegroundColorAttributeName] = UIColor.black.withAlphaComponent(0.8)
            font = CMViewUtilities.shared().regularFont(16)
		}
		doneButton.setAttributedTitle(NSAttributedString(string: "DONE", attributes: textAttributes), for: .normal)
		
        
		// for highlight state
		var highlightFont = CMViewUtilities.shared().regularFont(14)
        if NTCLayoutDetector().currentLayout().shouldUseIphoneUI == false {
            highlightFont = CMViewUtilities.shared().regularFont(16)
        }
        
		var highlightTextAttributes = [NSFontAttributeName: highlightFont, NSKernAttributeName: 1.0] as [String : Any]
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			highlightTextAttributes[NSForegroundColorAttributeName] = UIColor.white.withAlphaComponent(0.6)
		}else {
			highlightTextAttributes[NSForegroundColorAttributeName] = UIColor.black.withAlphaComponent(0.6)
		}
		doneButton.setAttributedTitle(NSAttributedString(string: "DONE", attributes: highlightTextAttributes), for: .highlighted)
		self.navigationController?.view.addSubview(doneButton)

		let leadingConstraint = NSLayoutConstraint(item: doneButton, attribute: .leading, relatedBy: .equal, toItem: self.tableView, attribute: .leading, multiplier: 1, constant: 0)
		let trailingConstraint = NSLayoutConstraint(item: doneButton, attribute: .trailing, relatedBy: .equal, toItem: self.tableView, attribute: .trailing, multiplier: 1, constant: 0)
		let bottomConstraint = NSLayoutConstraint(item: doneButton, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
		let height = NSLayoutConstraint(item: doneButton, attribute: .height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 60)

		self.navigationController?.view.addConstraints([leadingConstraint, trailingConstraint, bottomConstraint, height])

        if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
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
        }else {
            doneButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        }

        updateSelectedIndexPath(withRule: recurrenceRule)
    }

	fileprivate func setUpBackButton() {
		backButton.backgroundColor = .clear
		backButton.translatesAutoresizingMaskIntoConstraints = false
		backButton.isHidden = false
		backButton.addTarget(self, action: #selector(RecurrencePicker.closeButtonTapped(_:)), for: .touchUpInside)
		backButton.setImage(UIImage(named:"cal-back"), for: .normal)

		let leadingConstraint = NSLayoutConstraint(item: backButton, attribute: .leading, relatedBy: .equal, toItem: self.navigationController!.view, attribute: .leading, multiplier: 1, constant: 0)
		let topConstraint = NSLayoutConstraint(item: backButton, attribute: .top, relatedBy: .equal, toItem: self.navigationController!.view, attribute: .top, multiplier: 1, constant: 0)
		let width = NSLayoutConstraint(item: backButton, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 55)
		let height = NSLayoutConstraint(item: backButton, attribute: .height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 100)
		self.navigationController?.view.addSubview(backButton)
		self.navigationController!.view.addConstraints([leadingConstraint, topConstraint, width, height])
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
        footerView?.textLabel?.text = recurrenceRuleText()
        
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
}

extension RecurrencePicker: CustomRecurrenceViewControllerDelegate, UINavigationControllerDelegate {
    // MARK: - CustomRecurrenceViewController delegate
    func customRecurrenceViewController(_ controller: CustomRecurrenceViewController, didPickRecurrence recurrenceRule: RecurrenceRule) {
        self.recurrenceRule = recurrenceRule
        updateRecurrenceRuleText()
    }


	//MARK: UIViewControllerTransitioningDelegate Methods
	func NTCEventsPushPopAnimatorForPresentation(presenting: Bool) -> UIViewControllerAnimatedTransitioning
	{
		let animator = NTCEventsPushPopAnimator()
		animator.isPresenting = presenting
		return animator
	}

	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		return self.NTCEventsPushPopAnimatorForPresentation(presenting: true)
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		return self.NTCEventsPushPopAnimatorForPresentation(presenting: false)
	}

	//MARK: UINavigationControllerDelegate Methods
	public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		return self.NTCEventsPushPopAnimatorForPresentation(presenting: operation == UINavigationControllerOperation.push)
	}

	public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
	{
		return self.interactionController
	}



	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {


		let touchPoint = touch.location(in: self.navigationController!.view)

		if (self.tableView.frame.contains(touchPoint)) {
			return false
		}
		return false
	}

	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}

}
