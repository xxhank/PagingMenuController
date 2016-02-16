//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public protocol MenuItemContentView {
    static func viewWithOptions(title: String?, icon: UIImage?, options: PagingMenuOptions) -> MenuItemContentView
    func focused(selected: Bool, options: PagingMenuOptions)
    func sizeForTitle(title: String?, options: PagingMenuOptions) -> CGSize
}

//
// 带图标的选项卡
// 布局: [icon]-spacing-[title]
//
class IconLabelView: UIView, MenuItemContentView {
    private var titleLabel: UILabel = UILabel()
    private var iconView: UIImageView = UIImageView()
    private var spacing: CGFloat = 0.0

    class func viewWithOptions(title: String?, icon: UIImage?, options: PagingMenuOptions) -> MenuItemContentView {
        let view = IconLabelView(title: title, icon: icon, options: options)
        return view
    }

    init(title: String?, icon: UIImage?, options: PagingMenuOptions) {
        var frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        var width: CGFloat = 0
        var height: CGFloat = 0

        let label = self.titleLabel
        label.text = title!
        label.textColor = options.textColor
        label.font = options.font
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false

        label.sizeToFit()
        width = label.frame.width
        height = label.frame.height

        let iconView = self.iconView
        iconView.image = icon!
        iconView.sizeToFit()

        width = max(width, iconView.frame.width)
        height = max(height, iconView.frame.height)

        frame.size.width = width
        frame.size.height = height

        super.init(frame: frame)

        self.addSubview(self.titleLabel)
        self.addSubview(self.iconView)

        let viewsDictionary = ["icon": self.iconView, "title": self.titleLabel, "spacing": self.spacing]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[icon]-\(spacing)-[title]|", options: [], metrics: nil, views: viewsDictionary)
        let iconVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[icon]|", options: [], metrics: nil, views: viewsDictionary)
        let titleVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[title]|", options: [], metrics: nil, views: viewsDictionary)

        self.addConstraints(horizontalConstraints)
        self.addConstraints(iconVerticalConstraints)
        self.addConstraints(titleVerticalConstraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func focused(selected: Bool, options: PagingMenuOptions) {
        let titleLabel = self.titleLabel
        titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
        titleLabel.font = selected ? options.selectedFont : options.font
    }

    func sizeForTitle(title: String?, options: PagingMenuOptions) -> CGSize
    {
        let labelSize = NSString(string: title!)
            .boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self.titleLabel.font], context: nil).size

        let iconSize = self.iconView.frame.size

        let spacing = (labelSize.width == 0) ? 0 : self.spacing
        return CGSize(width: labelSize.width + iconSize.width + spacing, height: max(labelSize.height, iconSize.height))
    }
}

extension UILabel: MenuItemContentView {
    public class func viewWithOptions(title: String? = nil, icon: UIImage? = nil, options: PagingMenuOptions) -> MenuItemContentView {
        let label = UILabel()
        label.text = title
        label.textColor = options.textColor
        label.font = options.font
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false

        return label;
    }
    public func focused(selected: Bool, options: PagingMenuOptions) {
        self.textColor = selected ? options.selectedTextColor : options.textColor
        self.font = selected ? options.selectedFont : options.font
    }

    public func sizeForTitle(title: String?, options: PagingMenuOptions) -> CGSize {
        let labelSize = NSString(string: title!)
            .boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self.font], context: nil).size

        return labelSize;
    }
}

public class MenuItemView: UIView {

    public private(set) var contentView: MenuItemContentView!
    private var options: PagingMenuOptions!
    private var title: String!
    private var icon: UIImage!
    private var widthLabelConstraint: NSLayoutConstraint!
    private var itemIndex: Int!
    // MARK: - Lifecycle

    internal init(title: String, itemIndex: Int, options: PagingMenuOptions) {
        super.init(frame: CGRectZero)

        self.options = options
        self.title = title
        self.itemIndex = itemIndex
        setupView()
        constructLabel()
        layoutLabel()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    // MARK: - Constraints manager

    internal func updateLabelConstraints(size size: CGSize) {
        // set width manually to support ratotaion
        if case .SegmentedControl = options.menuDisplayMode {
            let labelSize = calculateLableSize(size)
            widthLabelConstraint.constant = labelSize.width
        }
    }

    // MARK: - Label changer

    internal func focusLabel(selected: Bool) {
        if case .RoundRect = options.menuItemMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
        }

        contentView.focused(selected, options: options)

        // adjust label width if needed
        let labelSize = calculateLableSize()
        widthLabelConstraint.constant = labelSize.width
    }

    // MARK: - Constructor

    private func setupView() {
        if case .RoundRect = options.menuItemMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = options.backgroundColor
        }
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func constructLabel() {

        if let menuItems = options.menuItems {
            let item = menuItems[itemIndex]
            contentView = IconLabelView.viewWithOptions(item["title"] as? String, icon: item["icon"] as? UIImage, options: options)
        } else {
            contentView = UILabel.viewWithOptions(self.title, icon: nil, options: options)
        }
        addSubview(contentView as! UIView)
    }

    private func layoutLabel() {
        let contentView = self.contentView as! UIView
        let viewsDictionary = ["view": contentView]

        let labelSize = calculateLableSize()

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)

        widthLabelConstraint = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: labelSize.width)
        widthLabelConstraint.active = true
    }

    // MARK: - Size calculator
    private func calculateLableSize(size: CGSize = UIScreen.mainScreen().bounds.size) -> CGSize {
        let labelSize = contentView.sizeForTitle(title, options: options)

        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case let .Standard(widthMode, _, _):
            itemWidth = labelWidth(labelSize, widthMode: widthMode)
        case .SegmentedControl:
            itemWidth = size.width / CGFloat(options.menuItemCount)
        case let .Infinite(widthMode):
            itemWidth = labelWidth(labelSize, widthMode: widthMode)
        }

        let itemHeight = floor(labelSize.height)
        return CGSizeMake(itemWidth + calculateHorizontalMargin() * 2, itemHeight)
    }

    private func labelWidth(labelSize: CGSize, widthMode: PagingMenuOptions.MenuItemWidthMode) -> CGFloat {
        switch widthMode {
        case .Flexible: return ceil(labelSize.width)
        case let .Fixed(width): return width
        }
    }

    private func calculateHorizontalMargin() -> CGFloat {
        if case .SegmentedControl = options.menuDisplayMode {
            return 0.0
        }
        return options.menuItemMargin
    }
}
