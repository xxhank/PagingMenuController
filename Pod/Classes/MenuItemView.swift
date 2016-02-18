//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit
import SnapKit

public class MenuItem {
    var title: String = ""

    required public init(title: String) {
        self.title = title
    }
}

public class IconTextMenuItem: MenuItem {
    var icon: UIImage
    var highlightedIcon: UIImage
    var spacing: CGFloat = 0.0

    required public init(title: String, icon: UIImage, highlightedIcon: UIImage, spacing: CGFloat) {
        self.icon = icon
        self.highlightedIcon = highlightedIcon
        self.spacing = spacing
        super.init(title: title)
    }

    required public init(title: String) {
        fatalError("init(title:) has not been implemented")
    }
}

public protocol MenuItemContent {
    static func viewWithOptions(menuItem: MenuItem, options: PagingMenuOptions) -> MenuItemContent
    func focused(selected: Bool, options: PagingMenuOptions)
    func sizeForTitle(title: String?, options: PagingMenuOptions) -> CGSize
}

//
// 带图标的选项卡
// 布局: [icon]-spacing-[title]
//

class IconLabelView: UIView, MenuItemContent {
    private var titleLabel: UILabel = UILabel()
    private var iconView: UIImageView = UIImageView()
    private var wrapperView: UIView = UIView()
    private var spacing: CGFloat = 18.0

    class func viewWithOptions(menuItem: MenuItem, options: PagingMenuOptions) -> MenuItemContent {
        let view = IconLabelView(menuItem: menuItem, options: options)
        return view
    }

    init(menuItem: MenuItem, options: PagingMenuOptions) {

        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        let iconTextMenuItem = menuItem as! IconTextMenuItem
        spacing = iconTextMenuItem.spacing

        let label = self.titleLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = iconTextMenuItem.title
        label.textColor = options.textColor
        label.font = options.font
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let iconView = self.iconView
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = iconTextMenuItem.icon
        iconView.highlightedImage = iconTextMenuItem.highlightedIcon

        let wrapperView = self.wrapperView
        wrapperView.addSubview(self.iconView)
        wrapperView.addSubview(self.titleLabel)

        self.iconView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(wrapperView.snp_top)
            make.bottom.equalTo(wrapperView.snp_bottom)
            make.leading.equalTo(wrapperView.snp_leading)
        }

        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(wrapperView.snp_centerY)
            make.trailing.equalTo(wrapperView.snp_trailing)
            make.leading.equalTo(self.iconView.snp_trailing).offset(spacing)
        }

        self.addSubview(wrapperView)
        wrapperView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self.center)
        }

        self.layer.borderWidth = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func focused(selected: Bool, options: PagingMenuOptions) {
        let titleLabel = self.titleLabel
        titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
        titleLabel.font = selected ? options.selectedFont : options.font
        
        self.iconView.highlighted = selected
    }

    func sizeForTitle(title: String?, options: PagingMenuOptions) -> CGSize
    {
        #if false
        let labelSize = NSString(string: title!)
            .boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self.titleLabel.font], context: nil).size

        let iconSize = self.iconView.frame.size

        let spacing = (labelSize.width == 0) ? 0 : self.spacing
        return CGSize(width: labelSize.width + iconSize.width + spacing, height: max(labelSize.height, iconSize.height))
        #else
        return self.wrapperView.intrinsicContentSize() ;
        #endif
    }

    override func intrinsicContentSize() -> CGSize {
        return self.wrapperView.intrinsicContentSize() ;
        #if false
        let iconSize = iconView.sizeThatFits(CGSize(width: CGFloat.max, height: CGFloat.max))
        let textSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.max, height: CGFloat.max))

        return CGSize(width: iconSize.width + spacing + textSize.width
        , height: max(iconSize.height, textSize.height))
        #endif
    }
}

extension UILabel: MenuItemContent {
    public class func viewWithOptions(menuItem: MenuItem, options: PagingMenuOptions) -> MenuItemContent {
        let label = UILabel()
        label.text = menuItem.title
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

    public private(set) var contentView: MenuItemContent!
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
            let menuItem = menuItems[itemIndex]
            contentView = IconLabelView.viewWithOptions(menuItem, options: options)
        } else {
            let menuItem = MenuItem(title: self.title)
            contentView = UILabel.viewWithOptions(menuItem, options: options)
        }
        if let subView = contentView as? UIView {
            subView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subView)
        }
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
