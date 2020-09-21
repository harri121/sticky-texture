//
//  StickyHeaderViewController.swift
//  Sticky-Texture
//
//  Created by Daniel Hariri on 21.09.20.
//

import AsyncDisplayKit
import Combine

public protocol StickyPageDelegate: class {
    func stickyPageDidScroll(page: StickyPageType)
    func stickyPageDidEndDragging(page: StickyPageType)
    func stickyPageDidStartReloading(page: StickyPageType)
}

public protocol StickyPageType: ASCollectionDelegate {
    var scrollView: UIScrollView { get }
    var viewController: UIViewController { get }
    var stickyDelegate: StickyPageDelegate? { get set }
    var reloadPublisher: AnyPublisher<Void, Error>? { get }
}

public class StickyHeaderViewController: ASDKViewController<ASDisplayNode> {
    
    private let spinnerHeight: CGFloat = 56.0
    
    private let navigationBarNode: StickyNavigationBarNode
    private let headerNode: StickyHeaderNode
    
    
    private lazy var spinnerNode: ASDisplayNode = {
        let node = ASDisplayNode(viewBlock: {
            let activityIndicatorView = UIActivityIndicatorView()
            activityIndicatorView.startAnimating()
            return activityIndicatorView
        })
        return node
    }()
    
    private lazy var spinnerContainerNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.backgroundColor = .clear
        node.style.width = ASDimension(unit: .fraction, value: 1.0)
        node.style.height = ASDimension(unit: .points, value: spinnerHeight)
        node.automaticallyManagesSubnodes = true
        node.layoutSpecBlock = { [unowned self] _, _ in
            let centerSpec = ASCenterLayoutSpec(
                horizontalPosition: .center, verticalPosition: .end,
                sizingOption: [], child: self.spinnerNode
            )
            return centerSpec
        }
        return node
    }()
    
    private let pagerNode: ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        let node = ASCollectionNode(collectionViewLayout: layout)
        node.style.width = ASDimension(unit: .fraction, value: 1.0)
        node.style.flexGrow = 1.0
        node.backgroundColor = .clear
        return node
    }()
    
    private var isLoading: Bool = false
    private var currentIndex: Int = -1
    private let pages: [StickyPageType]
    private var disposables = Set<AnyCancellable>()
    
    public init(navigationBarNode: StickyNavigationBarNode, headerNode: StickyHeaderNode, pages: [StickyPageType]) {
        self.navigationBarNode = navigationBarNode
        self.headerNode = headerNode
        self.pages = pages
        super.init(node: ASDisplayNode())
        node.automaticallyManagesSubnodes = true
        node.automaticallyRelayoutOnSafeAreaChanges = true
        node.automaticallyRelayoutOnLayoutMarginsChanges = true
        node.layoutSpecBlock = { [unowned self] node, _ in
            
            let headerStackChildren: [ASLayoutElement] = self.isLoading ?
                [self.headerNode, self.spinnerContainerNode] :
                [self.headerNode]
            let headerStackSpec = ASStackLayoutSpec(
                direction: .vertical, spacing: 0.0, justifyContent: .start,
                alignItems: .stretch, children: headerStackChildren
            )
            let headerInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: .infinity, right: 0.0)
            let headerInsetSpec = ASInsetLayoutSpec(insets: headerInsets, child: headerStackSpec)
            let headerOverlaySpec = ASOverlayLayoutSpec(child: self.pagerNode, overlay: headerInsetSpec)
            
            let navBarInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: .infinity, right: 0.0)
            let navBarInsetSpec = ASInsetLayoutSpec(insets: navBarInsets, child: self.navigationBarNode)
            let navigationBarOverlaySpec = ASOverlayLayoutSpec(child: headerOverlaySpec, overlay: navBarInsetSpec)
            
            let insetTop = node.safeAreaInsets.top
            let insets = UIEdgeInsets(top: insetTop, left: 0.0, bottom: 0.0, right: 0.0)
            let insetSpec = ASInsetLayoutSpec(insets: insets, child: navigationBarOverlaySpec)
            return insetSpec
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    public override func viewDidLayoutSubviews() {
        if pages.isEmpty { return }
        let page = pages[currentIndex]
        updateScrollViewInsets(page: page)
    }
    
    private func setup() {
        pagerNode.view.contentInsetAdjustmentBehavior = .never
        pagerNode.view.isScrollEnabled = false
        pagerNode.view.isPagingEnabled = true
        pagerNode.showsVerticalScrollIndicator = false
        pagerNode.showsHorizontalScrollIndicator = false
        pagerNode.dataSource = self
        pagerNode.delegate = self
        setPage(index: 0, animated: false)
    }
    
    public func setPage(index: Int, animated: Bool) {
        
        if pages.isEmpty { return }
        
        let oldIndex = currentIndex
        currentIndex = index
        let page = pages[index]
        
        if (oldIndex != index) {
            if oldIndex >= 0 {
                pages[oldIndex].viewController.removeFromParent()
            }
            addChild(page.viewController)
            didMove(toParent: page.viewController)
        }
        
        page.scrollView.alwaysBounceVertical = true
        page.scrollView.showsVerticalScrollIndicator = false
        page.stickyDelegate = self
        isLoading = isLoading && page.reloadPublisher != nil
        updateScrollViewInsets(page: page)
        scrollDidUpdate(page: page)
        let indexPath = IndexPath(item: index, section: 0)
        pagerNode.scrollToItem(at: indexPath, at: .left, animated: animated)
        
        if oldIndex >= 0 {
            let oldPage = pages[oldIndex]
            
            // hide keyboard
            oldPage.viewController.view.endEditing(true)
            let offset = CGPoint(x: 0.0, y: oldPage.scrollView.contentOffset.y)
            page.scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    private func tryReloading(page: StickyPageType) {
        guard !isLoading, let reloadPublisher = page.reloadPublisher else { return }
        isLoading = true
        updateScrollViewInsets(page: page)
        scrollDidUpdate(page: page)
        node.setNeedsLayout()
        
        reloadPublisher
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure:
                        self?.isLoading = false
                    default:
                        break
                    }
            },
            receiveValue: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.isLoading = false
                let currentPage = strongSelf.pages[strongSelf.currentIndex]
                strongSelf.updateScrollViewInsets(page: currentPage)
                strongSelf.node.setNeedsLayout()
            })
            .store(in: &disposables)
    }
    
    private func updateScrollViewInsets(page: StickyPageType) {
        let scrollView = page.scrollView
        // set the inset for the scroll view based on the idle header height
        let scrollInsetTop = headerNode.maxHeight + (isLoading ? spinnerHeight : 0.0)
        let scrollInsetBottom: CGFloat = 0.0
        scrollView.contentInset = UIEdgeInsets(top: scrollInsetTop, left: 0.0, bottom: scrollInsetBottom, right: 0.0)
    }
    
    private func scrollDidUpdate(page: StickyPageType) {
        let scrollView = page.scrollView
        let contentOffsetY = scrollView.contentOffset.y
        let adjustedOffsetY = contentOffsetY + scrollView.contentInset.top

        let headerHeight = adjustedOffsetY < 0 ?
            min(headerNode.maxHeight - adjustedOffsetY, headerNode.maxHeight + headerNode.maxStretch) :
            max(headerNode.minHeight, headerNode.maxHeight - adjustedOffsetY)
    
        headerNode.style.height = ASDimension(unit: .points, value: headerHeight)
        headerNode.setNeedsLayout()
        
        // scroll indicator insets
        let scrollIndicatorInsetsTop = headerHeight + (isLoading ? spinnerHeight : 0.0)
        let scrollIndicatorInsetsBottom: CGFloat = 0.0//node.safeAreaInsets.bottom
        
        scrollView.scrollIndicatorInsets = UIEdgeInsets(
        top: scrollIndicatorInsetsTop, left: 0.0, bottom: scrollIndicatorInsetsBottom, right: 0.0)
        
        // update collapse progress
        updateCollapseProgress(page: page)
    }
    
    private var lastCollapseProgress: CGFloat?
    private func updateCollapseProgress(page: StickyPageType) {
        
        let headerHeight = headerNode.style.height.value
        let progressRange = headerNode.maxHeight - headerNode.minHeight
        if progressRange > 0 {
            let collapseProgress =  min(max((headerNode.maxHeight - headerHeight)/progressRange, 0.0), 1.0)
            
            let previousCollapseProgress = lastCollapseProgress ?? collapseProgress
            lastCollapseProgress = collapseProgress
            let animated = abs(collapseProgress - previousCollapseProgress) < 0.1
            headerNode.setCollapseProgress(collapseProgress, animated: animated)
            navigationBarNode.setCollapseProgress(collapseProgress, animated: animated)
        }
    }
}

extension StickyHeaderViewController: StickyPageDelegate {
    
    public func stickyPageDidScroll(page: StickyPageType) {
        scrollDidUpdate(page: page)
    }
    
    public  func stickyPageDidEndDragging(page: StickyPageType) {
        let scrollView = page.scrollView
        guard !isLoading else { return }
        let contentOffsetY = scrollView.contentOffset.y
        let adjustedOffsetY = contentOffsetY + scrollView.contentInset.top
        if adjustedOffsetY < 0 && (headerNode.maxHeight - adjustedOffsetY > headerNode.maxHeight + headerNode.maxStretch) {
            tryReloading(page: page)
        }
    }
    
    public func stickyPageDidStartReloading(page: StickyPageType) {
        tryReloading(page: page)
    }
}

extension StickyHeaderViewController: ASCollectionDataSource, ASCollectionDelegate {
    
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let page = pages[indexPath.item]
        let cellNode = ASCellNode(viewControllerBlock: {
            return page.viewController
        }, didLoad: nil)
        cellNode.backgroundColor = .clear
        
        let height = UIScreen.main.bounds.height - UIEdgeInsets.globalSafeAreaInsets.top
        cellNode.style.width = ASDimension(unit: .points, value: collectionNode.bounds.width)
        cellNode.style.height = ASDimension(unit: .points, value: height)
        return cellNode
    }
}

