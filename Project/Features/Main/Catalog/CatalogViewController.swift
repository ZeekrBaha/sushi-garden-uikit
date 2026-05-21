import UIKit
import Combine

final class CatalogViewController: UIViewController {
    let viewModel: CatalogViewModel
    private var cancellables = Set<AnyCancellable>()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    enum Section: Int, CaseIterable {
        case categories, products
    }

    enum Item: Hashable {
        case category(Category)
        case product(Product)
    }

    init(viewModel: CatalogViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupCollectionView()
        configureDataSource()
        bindViewModel()
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch Section(rawValue: sectionIndex)! {
            case .categories:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(90),
                    heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(90),
                    heightDimension: .absolute(40))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = Spacing.s
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: Spacing.m, leading: Spacing.m,
                    bottom: Spacing.m, trailing: Spacing.m)
                return section

            case .products:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.5),
                    heightDimension: .absolute(230))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: Spacing.s / 2,
                    bottom: 0, trailing: Spacing.s / 2)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(230))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item, item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = Spacing.s
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: Spacing.s / 2,
                    bottom: Spacing.m, trailing: Spacing.s / 2)
                return section
            }
        }
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.register(CategoryTabCell.self,
                                forCellWithReuseIdentifier: CategoryTabCell.reuseIdentifier)
        collectionView.register(ProductCell.self,
                                forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .category(let category):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CategoryTabCell.reuseIdentifier,
                    for: indexPath) as! CategoryTabCell
                cell.configure(name: category.name,
                               isSelected: category.id == self.viewModel.selectedCategoryId)
                return cell

            case .product(let product):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ProductCell.reuseIdentifier,
                    for: indexPath) as! ProductCell
                cell.configure(with: product)
                cell.onAddTapped = { [weak self] in self?.viewModel.addToCart(product) }
                return cell
            }
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$displayedProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applySnapshot() }
            .store(in: &cancellables)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        let categoryItems = viewModel.categories.map { Item.category($0) }
        let productItems = viewModel.displayedProducts.map { Item.product($0) }
        snapshot.appendItems(categoryItems, toSection: .categories)
        snapshot.appendItems(productItems, toSection: .products)
        // Reconfigure category cells so selected state reflects current selectedCategoryId
        snapshot.reconfigureItems(categoryItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate

extension CatalogViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .category(let category):
            viewModel.selectCategory(category.id)
        case .product(let product):
            viewModel.selectProduct(product)
        }
    }
}
