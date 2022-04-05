import UIKit

class MenuCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, Storyboarded {
    
    static var storyboardName = "MenuStoryboard"
    weak var coordinator: MainCoordinator?
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Variables
    var parentVC: WaitingRoomViewController!
    
    let numberOfPages = 2
    var pages: [UIImage] {
        var pages: [UIImage] = []
        for index in 1...numberOfPages {
            pages.append(UIImage(named: "Menu_page\(index)")!)
        }
        return pages
    }
    
    // MARK: - Scene Lifecycle
    
    override func viewDidLoad() {
        pageControl.numberOfPages = numberOfPages
        
        // if iPad
        _ = collectionViewBottomConstraint.setMultiplier(multiplier: traitCollection.verticalSizeClass == .regular ? 1 : 0.86)
    }
    
    // MARK: - Methods
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Collection Methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "menuCell", for: indexPath) as! MenuCollectionViewCell
        cell.menuImage.image = pages[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.safeAreaLayoutGuide.layoutFrame.size.width
        let height = view.safeAreaLayoutGuide.layoutFrame.size.height
        
        let widthMultiplier: CGFloat = collectionViewWidthConstraint.multiplier
        return CGSize(width: widthMultiplier * width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(self.collectionView.contentOffset.x)/Int(self.collectionView.frame.width)
    }
    
}
