import UIKit

@MainActor
final class NestedCollectionViewController: ExampleSidebarViewController {
    private let parentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.backgroundColor = .systemGroupedBackground
        return collectionView
    }()

    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.text =
            "Swipe left to move the parent to page 2.\nThen swipe right inside the child list: the parent should move back and the sidebar should stay closed.\nOn page 1, swipe right inside the child list to open the sidebar."
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nested Collections"
        view.backgroundColor = .systemGroupedBackground

        parentCollectionView.register(
            NestedCollectionPageCell.self,
            forCellWithReuseIdentifier: NestedCollectionPageCell.reuseIdentifier
        )
        parentCollectionView.dataSource = self
        parentCollectionView.delegate = self

        view.addSubview(instructionsLabel)
        view.addSubview(statusLabel)
        view.addSubview(parentCollectionView)
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        parentCollectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            instructionsLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 12
            ),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: instructionsLabel.trailingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: instructionsLabel.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 16),
            parentCollectionView.topAnchor.constraint(
                equalTo: statusLabel.bottomAnchor,
                constant: 8
            ),
            parentCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parentCollectionView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(
                equalTo: parentCollectionView.bottomAnchor
            ),
        ])

        updateStatusLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateStatusLabel()
    }

    private func updateStatusLabel() {
        let pageWidth = max(parentCollectionView.bounds.width, 1)
        let page = Int((parentCollectionView.contentOffset.x / pageWidth).rounded()) + 1
        statusLabel.text = "Parent page: \(page) / 3"
    }
}

@MainActor
extension NestedCollectionViewController: UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        3
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: NestedCollectionPageCell.reuseIdentifier,
                for: indexPath
            ) as! NestedCollectionPageCell
        cell.configure(page: indexPath.item + 1)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === parentCollectionView else { return }
        updateStatusLabel()
    }
}

@MainActor
private final class NestedCollectionPageCell: UICollectionViewCell {
    static let reuseIdentifier = "NestedCollectionPageCell"

    private let childCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceVertical = true
        collectionView.alwaysBounceHorizontal = false
        collectionView.isDirectionalLockEnabled = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private var page = 1

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(childCollectionView)
        childCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            childCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: childCollectionView.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: childCollectionView.trailingAnchor),
        ])

        childCollectionView.register(
            NestedCollectionRowCell.self,
            forCellWithReuseIdentifier: NestedCollectionRowCell.reuseIdentifier
        )
        childCollectionView.dataSource = self
        childCollectionView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(page: Int) {
        self.page = page
        childCollectionView.reloadData()
        childCollectionView.setContentOffset(.zero, animated: false)
    }
}

@MainActor
extension NestedCollectionPageCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        30
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: NestedCollectionRowCell.reuseIdentifier,
                for: indexPath
            ) as! NestedCollectionRowCell
        cell.configure(title: "Page \(page) · Child row \(indexPath.item + 1)")
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width - 32, height: 58)
    }
}

@MainActor
private final class NestedCollectionRowCell: UICollectionViewCell {
    static let reuseIdentifier = "NestedCollectionRowCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12

        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
