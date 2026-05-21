import UIKit
import MapKit
import Combine

final class CheckoutViewController: UIViewController {
    let viewModel: CheckoutViewModel
    private var cancellables = Set<AnyCancellable>()

    private let mapView = MKMapView()
    private let pin = MKPointAnnotation()
    private let addressLabel = UILabel()
    private let geocodeErrorLabel = UILabel()
    private let summaryLabel = UILabel()
    private let confirmButton = PrimaryButton()

    private static let moscowCoordinate = CLLocationCoordinate2D(
        latitude: 55.7558, longitude: 37.6173)

    init(viewModel: CheckoutViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupLayout()
        setupMap()
        bindViewModel()
        updateSummary()
    }

    private func setupLayout() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        addressLabel.text = "Выберите адрес на карте"
        addressLabel.textColor = AppColor.textPrimary
        addressLabel.font = AppFont.productTitle
        addressLabel.numberOfLines = 2
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        geocodeErrorLabel.text = "Не удалось определить адрес"
        geocodeErrorLabel.textColor = AppColor.accent
        geocodeErrorLabel.font = AppFont.caption
        geocodeErrorLabel.isHidden = true
        geocodeErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        summaryLabel.textColor = AppColor.textSecondary
        summaryLabel.font = AppFont.caption
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false

        confirmButton.setTitle("Подтвердить заказ", for: .normal)
        confirmButton.isEnabled = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let infoStack = UIStackView(
            arrangedSubviews: [addressLabel, geocodeErrorLabel, summaryLabel, confirmButton])
        infoStack.axis = .vertical
        infoStack.spacing = Spacing.m
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

            infoStack.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: Spacing.m),
            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.m),
        ])
    }

    private func setupMap() {
        mapView.delegate = self
        let region = MKCoordinateRegion(
            center: Self.moscowCoordinate,
            latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(region, animated: false)
        pin.coordinate = Self.moscowCoordinate
        mapView.addAnnotation(pin)
    }

    private func bindViewModel() {
        viewModel.$address
            .receive(on: DispatchQueue.main)
            .sink { [weak self] addr in
                guard let self else { return }
                if !addr.isEmpty { addressLabel.text = addr }
                confirmButton.isEnabled = viewModel.canPlaceOrder
            }
            .store(in: &cancellables)

        viewModel.$geocodingFailed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failed in
                self?.geocodeErrorLabel.isHidden = !failed
            }
            .store(in: &cancellables)
    }

    private func updateSummary() {
        let count = viewModel.items.reduce(0) { $0 + $1.quantity }
        summaryLabel.text = "\(count) товар · \(viewModel.totalPrice) ₽"
    }

    @objc private func confirmTapped() {
        viewModel.placeOrder()
    }
}

extension CheckoutViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "DraggablePin"
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        pinView.annotation = annotation
        pinView.isDraggable = true
        pinView.markerTintColor = AppColor.accent
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 didChange newState: MKAnnotationView.DragState,
                 fromOldState oldState: MKAnnotationView.DragState) {
        guard newState == .none, let coordinate = view.annotation?.coordinate else { return }
        viewModel.reverseGeocode(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}
