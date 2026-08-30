import Combine
import CoreLocation
import Foundation

/// Egy helyminta a pálya síkjában, méterben az első fixhez képest.
struct PitchPoint {
    var x: Double
    var y: Double
    var time: Date
}

/// A meccs alatti mozgás rögzítése, majd hőtérképpé alakítása.
///
/// Csak nyílt terepen működik: fedett pályán nincs GPS-jel. Ha a párosított iPhone
/// Bluetooth-hatótávon belül van, a watchOS átveheti annak a helyadatát az óráé
/// helyett – ezt nem lehet API-ból kikapcsolni, ezért a végén megvizsgáljuk, hogy a
/// nyom tényleg mozgott-e együtt a viselőjével.
final class PitchTracker: NSObject, ObservableObject {
    @Published private(set) var isTracking = false
    /// Ha a helymeghatározás nem indult el, itt az oka.
    @Published var locationProblem: String?

    private let manager = CLLocationManager()
    private var points: [PitchPoint] = []
    private var origin: CLLocation?
    private var isPaused = false

    /// Ennél pontatlanabb fixet eldobunk: kispályán a 20 méter már használhatatlan.
    private static let accuracyLimit: CLLocationAccuracy = 20
    /// Két minta között ennyi időt számítunk be legfeljebb, hogy egy jelkimaradás ne
    /// halmozzon percnyi állást egyetlen cellába.
    private static let maxGap: TimeInterval = 5
    /// Ennyi használható minta alatt nem rajzolunk térképet.
    private static let minSamples = 120
    /// Ennél kisebb mozgásterület nem lehet kispálya. Egy mezőnyjátékos egy meccs
    /// alatt bejárja a pálya hosszát; ami ennél szűkebb, az álló vagy sodródó jel.
    private static let minLengthMeters = 20.0
    private static let minWidthMeters = 5.0
    /// Ennyi mintát átlagolunk, mielőtt a nyom hosszát mérjük.
    private static let smoothingWindow = 5

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
    }

    // MARK: - Életciklus

    /// A beállítás bekapcsolásakor kérjük az engedélyt, ne a meccs kezdetén.
    func requestAuthorization() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        guard !isTracking else { return }
        points = []
        origin = nil
        isPaused = false
        locationProblem = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationProblem = "A helymeghatározás le van tiltva, hőtérkép nem készül."
            return
        default:
            break
        }

        manager.startUpdatingLocation()
        isTracking = true
    }

    /// Félidőben és óramegállításnál a gyűjtés is áll – különben a partvonalon
    /// ácsorgás égetné be magát a térképbe.
    func pause() {
        guard isTracking, !isPaused else { return }
        isPaused = true
        manager.stopUpdatingLocation()
    }

    func resume() {
        guard isTracking, isPaused else { return }
        isPaused = false
        manager.startUpdatingLocation()
    }

    /// Lezárja a gyűjtést, és visszaadja a térképet vagy az elmaradás okát.
    /// A `workoutDistanceMeters` az edzés mért távja – ehhez hasonlítjuk a nyomot.
    func finish(workoutDistanceMeters: Double) -> (heatmap: PitchHeatmap?, note: String?) {
        manager.stopUpdatingLocation()
        let wasTracking = isTracking
        isTracking = false
        isPaused = false

        let collected = points
        points = []
        origin = nil

        // Kikapcsolt hőtérképnél nincs mit jelenteni – ne írjunk „nem volt jel" üzenetet.
        guard wasTracking || !collected.isEmpty else { return (nil, nil) }

        if let locationProblem {
            return (nil, locationProblem)
        }
        return Self.buildHeatmap(from: collected, workoutDistanceMeters: workoutDistanceMeters)
    }

    func cancel() {
        manager.stopUpdatingLocation()
        isTracking = false
        isPaused = false
        points = []
        origin = nil
    }

    // MARK: - Hőtérkép építése

    /// Tiszta függvény: pontfelhőből rács. Nincs benne se hálózat, se UI, se állapot.
    static func buildHeatmap(from points: [PitchPoint],
                             workoutDistanceMeters: Double) -> (PitchHeatmap?, String?) {
        guard points.count >= minSamples else {
            return (nil, "Nem volt elég GPS-jel a hőtérképhez.")
        }

        // A mozgásterület főtengelye (PCA): a szórásmátrix nagyobbik sajátvektora.
        let count = Double(points.count)
        let meanX = points.reduce(0) { $0 + $1.x } / count
        let meanY = points.reduce(0) { $0 + $1.y } / count
        var varianceX = 0.0, varianceY = 0.0, covariance = 0.0
        for point in points {
            let dx = point.x - meanX
            let dy = point.y - meanY
            varianceX += dx * dx
            varianceY += dy * dy
            covariance += dx * dy
        }
        varianceX /= count
        varianceY /= count
        covariance /= count

        // Elforgatjuk a felhőt úgy, hogy a leghosszabb kiterjedés vízszintes legyen.
        let angle = 0.5 * atan2(2 * covariance, varianceX - varianceY)
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        let rotated = points.map { point -> (u: Double, v: Double, time: Date) in
            let dx = point.x - meanX
            let dy = point.y - meanY
            return (dx * cosAngle + dy * sinAngle, -dx * sinAngle + dy * cosAngle, point.time)
        }

        // Szélső értékek helyett 2–98 százalék: egy-egy elszálló fix ne nyújtsa szét a rácsot.
        let sortedU = rotated.map(\.u).sorted()
        let sortedV = rotated.map(\.v).sorted()
        let minU = percentile(sortedU, 0.02)
        let maxU = percentile(sortedU, 0.98)
        let minV = percentile(sortedV, 0.02)
        let maxV = percentile(sortedV, 0.98)

        let length = maxU - minU
        let width = maxV - minV

        guard length >= minLengthMeters, width >= minWidthMeters else {
            return (nil, "Túl kicsi területen mozgott a helyadat – valószínűleg a telefonét kaptuk.")
        }

        // Ha az edzés szerint futottál, de a nyom szerint álltál, a helyadat nem téged
        // követett. A nyomot előbb simítjuk: nyersen a mintánkénti GPS-zaj több
        // kilométerre fújná fel egy álló pont „megtett útját" is.
        let smoothed = movingAverage(rotated)
        let pathLength = zip(smoothed, smoothed.dropFirst()).reduce(0.0) { total, pair in
            total + hypot(pair.1.u - pair.0.u, pair.1.v - pair.0.v)
        }
        if workoutDistanceMeters > 500, pathLength < workoutDistanceMeters * 0.3 {
            return (nil, "A helyadat nem követte a mozgásodat – hagyd a telefont hatótávon kívül.")
        }

        var cells = [Double](repeating: 0, count: PitchHeatmap.columns * PitchHeatmap.rows)
        for (current, next) in zip(rotated, rotated.dropFirst()) {
            let elapsed = min(maxGap, max(0, next.time.timeIntervalSince(current.time)))
            guard elapsed > 0 else { continue }
            let column = gridIndex((current.u - minU) / length, steps: PitchHeatmap.columns)
            let row = gridIndex((current.v - minV) / width, steps: PitchHeatmap.rows)
            cells[row * PitchHeatmap.columns + column] += elapsed
        }

        let heatmap = PitchHeatmap(cells: cells,
                                   lengthMeters: length,
                                   widthMeters: width,
                                   sampleCount: points.count)
        guard heatmap.totalTime >= 60 else {
            return (nil, "Túl rövid ideig volt GPS-jel a hőtérképhez.")
        }
        return (heatmap, nil)
    }

    /// Csúszóablakos átlag a nyom simítására.
    private static func movingAverage(
        _ points: [(u: Double, v: Double, time: Date)]
    ) -> [(u: Double, v: Double)] {
        let half = smoothingWindow / 2
        return points.indices.map { position -> (u: Double, v: Double) in
            let lower = max(0, position - half)
            let upper = min(points.count - 1, position + half)
            let window = points[lower...upper]
            let count = Double(window.count)
            return (window.reduce(0) { $0 + $1.u } / count,
                    window.reduce(0) { $0 + $1.v } / count)
        }
    }

    private static func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let position = Int((Double(sorted.count - 1) * fraction).rounded())
        return sorted[min(max(position, 0), sorted.count - 1)]
    }

    private static func gridIndex(_ normalized: Double, steps: Int) -> Int {
        min(steps - 1, max(0, Int(normalized * Double(steps))))
    }
}

extension PitchTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            guard !self.isPaused else { return }
            for location in locations {
                guard location.horizontalAccuracy > 0,
                      location.horizontalAccuracy <= Self.accuracyLimit else { continue }

                guard let origin = self.origin else {
                    self.origin = location
                    self.points.append(PitchPoint(x: 0, y: 0, time: location.timestamp))
                    continue
                }

                // Kis területen a sík közelítés bőven elég: 50 méteren a gömbi hiba milliméteres.
                let metersPerDegree = 111_320.0
                let latitudeScale = cos(origin.coordinate.latitude * .pi / 180)
                let dy = (location.coordinate.latitude - origin.coordinate.latitude) * metersPerDegree
                let dx = (location.coordinate.longitude - origin.coordinate.longitude)
                    * metersPerDegree * latitudeScale
                self.points.append(PitchPoint(x: dx, y: dy, time: location.timestamp))
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A CoreLocation átmeneti hibát is jelez, amíg keresi a jelet. Csak az
        // elutasítás végleges – egyébként némán tovább próbálkozunk.
        guard (error as? CLError)?.code == .denied else { return }
        DispatchQueue.main.async {
            self.locationProblem = "A helymeghatározás le van tiltva, hőtérkép nem készül."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .denied, .restricted:
                self.locationProblem = "A helymeghatározás le van tiltva, hőtérkép nem készül."
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationProblem = nil
                if self.isTracking, !self.isPaused {
                    manager.startUpdatingLocation()
                }
            default:
                break
            }
        }
    }
}
