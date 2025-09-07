import Foundation
import SQLite

class DatabaseManager: ObservableObject {
    private var db: Connection?
    private let dbPath: String
    
    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        dbPath = documentsURL.appendingPathComponent("CaminoPython.sqlite").path
        
        do {
            db = try Connection(dbPath)
            // Pragmas for stability/perf
            try db?.execute("PRAGMA journal_mode = WAL;")
            try db?.execute("PRAGMA foreign_keys = ON;")
            
            print("Database connected successfully at: \(dbPath)")
            print("Database URL: \(documentsURL.appendingPathComponent("CaminoPython.sqlite"))")
            createTables()
            
        } catch {
            print("Database connection failed: \(error)")
        }
    }
    
    // MARK: - Upload Tables (reference + legacy)
    
    // Waypoints (legacy/table name without trail prefix)
    private let waypointsTable = Table("viafrancigena_waypoints")
    private let waypoint_id = Expression<Int64>("id_no")
    private let waypoint_seq = Expression<Int>("seq") // NEW: deterministic order
    private let waypoint_latitude = Expression<Double>("latitude")
    private let waypoint_longitude = Expression<Double>("longitude")
    private let waypoint_elevation = Expression<Double>("elevation")
    private let waypoint_distance = Expression<Double>("distance") // per-segment distance
    private let waypoint_hike_city = Expression<String?>("hike_city")
    private let waypoint_gain = Expression<Double>("gain")
    private let waypoint_loss = Expression<Double>("loss")
    private let waypoint_pace_dist = Expression<Int>("pace_dist")
    private let waypoint_pace_gain = Expression<Int>("pace_gain")
    private let waypoint_FME = Expression<String>("FME")
    private let waypoint_facilities = Expression<String?>("facilities")
    private let waypoint_variant_city = Expression<String?>("variant_city")
    
    // Attractions table
    private let attractionsTable = Table("viafrancigena_attractions")
    private let attraction_id = Expression<Int64>("id_no")
    private let attraction_city = Expression<String>("attraction_city")
    private let attraction = Expression<String>("attraction")
    private let attraction_map = Expression<String?>("attraction_map")
    
    // Zeros table
    private let zerosTable = Table("viafrancigena_zeros")
    private let zero_id = Expression<Int64>("id_no")
    private let zero_city = Expression<String>("zero_city")
    
    // Reference tables (with enabled columns)
    private let categoryTable = Table("caminopython_category")
    private let category_id = Expression<Int64>("id_no")
    private let category_name = Expression<String>("category")
    private let category_type = Expression<String?>("category_type")
    private let category_enabled = Expression<Bool>("enabled")
    
    private let currencyTable = Table("caminopython_currency")
    private let currency_id = Expression<Int64>("id_no")
    private let currency_name = Expression<String>("currency")
    private let currency_exchange_rate = Expression<Double>("exchange_rate")
    private let currency_enabled = Expression<Bool>("enabled")
    
    private let paymentTable = Table("caminopython_payment")
    private let payment_id = Expression<Int64>("id_no")
    private let payment_type_name = Expression<String>("payment_type")
    private let payment_name = Expression<String>("payment")
    private let payment_enabled = Expression<Bool>("enabled")
    
    // App config (current trail, etc.)
    private let appConfigTable = Table("app_config")
    private let app_config_key = Expression<String>("key")
    private let app_config_value = Expression<String>("value")
    
    // MARK: - App Created Tables
    
    // Trip table (dynamic function)
    private func tripTableFor(trail: String) -> Table {
        return Table("\(trail)_trip")
    }
    
    private let trip_id = Expression<Int64>("id_no")
    private let trip_start_date = Expression<String>("trip_start_date")
    private let trip_return_date = Expression<String>("trip_return_date")
    private let trip_distance = Expression<Double>("trip_distance")
    private let trip_gain = Expression<Double>("trip_gain")
    private let trip_loss = Expression<Double>("trip_loss")
    private let trip_slope = Expression<Double>("trip_slope")
    private let trip_days = Expression<Int>("trip_days")
    private let select_trail = Expression<String>("select_trail")
    private let trip_title = Expression<String>("trip_title")
    private let distance_uom = Expression<String>("distance_uom")
    private let temp_uom = Expression<String>("temp_uom")
    private let weight_uom = Expression<String>("weight_uom")
    private let planning_range = Expression<Double?>("planning_range")
    
    // Plan table
    private let planTable = Table("viafrancigena_plan")
    private let plan_id = Expression<Int64>("id_no")
    private let plan_date = Expression<String>("date")
    private let plan_stop_city = Expression<String>("stop_city")
    private let plan_distance = Expression<Double>("plan_distance")
    private let plan_gain = Expression<Double>("plan_gain")
    private let plan_loss = Expression<Double>("plan_loss")
    private let plan_slope = Expression<Double>("plan_slope")
    private let plan_duration = Expression<String>("plan_duration")
    private let plan_stop_type = Expression<String>("stop_type")
    
    // Mileage table
    private let mileageTable = Table("viafrancigena_mileage")
    private let mileage_id = Expression<Int64>("id_no")
    private let mileage_date = Expression<String>("date")
    private let mileage_stop_city = Expression<String>("stop_city")
    private let mileage_stop_type = Expression<String>("stop_type")
    private let mileage_start_time = Expression<String?>("start_time")
    private let mileage_stop_time = Expression<String?>("stop_time")
    private let mileage_actual_distance = Expression<Double?>("actual_distance")
    private let mileage_actual_gain = Expression<Double?>("actual_gain")
    private let mileage_actual_loss = Expression<Double?>("actual_loss")
    private let mileage_actual_slope = Expression<Double?>("actual_slope")
    private let mileage_actual_duration = Expression<String?>("actual_duration")
    private let mileage_actual_moving = Expression<String?>("actual_moving")
    private let mileage_actual_pace = Expression<String?>("actual_pace")
    private let mileage_zero_distance = Expression<Double?>("zero_distance")
    private let mileage_high_temp = Expression<String?>("high_temp")
    private let mileage_pilgrims = Expression<Int?>("pilgrims")
    private let mileage_note = Expression<String?>("note_mileage")
    
    // Expense table
    private let expenseTable = Table("viafrancigena_expense")
    private let expense_id = Expression<Int64>("id_no")
    private let expense_date = Expression<String>("date")
    private let expense_stop_city = Expression<String>("stop_city")
    private let expense_stop_type = Expression<String>("stop_type")
    private let expense_payment = Expression<String>("payment")
    private let expense_payment_type = Expression<String>("payment_type")
    private let expense_category = Expression<String>("expense_category")
    private let expense_type = Expression<String>("expense_type")
    private let expense_vendor = Expression<String?>("vendor")
    private let expense_local_amount = Expression<Double>("local_amount")
    private let expense_currency = Expression<String>("currency")
    private let expense_usd_amount = Expression<Double>("usd_amount") // RENAMED
    private let expense_note = Expression<String?>("note_expense")
    
    // MARK: - Table Creation
    
    private func createTables() {
        guard let db = db else { return }
        
        do {
            // App config
            try db.run(appConfigTable.create(ifNotExists: true) { t in
                t.column(app_config_key, primaryKey: true)
                t.column(app_config_value)
            })
            
            // Reference tables first (no auto-seeding)
            try createReferenceTablesIfNeeded()
            
            // Legacy tables for compatibility
            try createLegacyTablesIfNeeded()
            
            print("All tables created successfully")
            
        } catch {
            print("Error creating tables: \(error)")
        }
    }
    
    private func createReferenceTablesIfNeeded() throws {
        guard let db = db else { return }
        
        try db.run(categoryTable.create(ifNotExists: true) { t in
            t.column(category_id, primaryKey: .autoincrement)
            t.column(category_name)
            t.column(category_type)
            t.column(category_enabled, defaultValue: true)
        })
        
        try db.run(currencyTable.create(ifNotExists: true) { t in
            t.column(currency_id, primaryKey: .autoincrement)
            t.column(currency_name)
            t.column(currency_exchange_rate, defaultValue: 1.0)
            t.column(currency_enabled, defaultValue: true)
        })
        
        try db.run(paymentTable.create(ifNotExists: true) { t in
            t.column(payment_id, primaryKey: .autoincrement)
            t.column(payment_type_name)
            t.column(payment_name)
            t.column(payment_enabled, defaultValue: true)
        })
        
        // NOTE: No automatic inserts here (we removed seeding).
    }
    
    private func createLegacyTablesIfNeeded() throws {
        guard let db = db else { return }
        
        // Waypoints legacy table
        try db.run(waypointsTable.create(ifNotExists: true) { t in
            t.column(waypoint_id, primaryKey: .autoincrement)
            t.column(waypoint_seq)            // NEW
            t.column(waypoint_latitude)
            t.column(waypoint_longitude)
            t.column(waypoint_elevation)
            t.column(waypoint_distance)
            t.column(waypoint_hike_city)
            t.column(waypoint_gain)
            t.column(waypoint_loss)
            t.column(waypoint_pace_dist)
            t.column(waypoint_pace_gain)
            t.column(waypoint_FME)
            t.column(waypoint_facilities)
            t.column(waypoint_variant_city)
        })
        try createWaypointIndexesIfNeeded(for: "viafrancigena") // index seq/city
        
        try db.run(attractionsTable.create(ifNotExists: true) { t in
            t.column(attraction_id, primaryKey: .autoincrement)
            t.column(attraction_city)
            t.column(attraction)
            t.column(attraction_map)
        })
        
        try db.run(zerosTable.create(ifNotExists: true) { t in
            t.column(zero_id, primaryKey: .autoincrement)
            t.column(zero_city)
        })
        
        // Trip table (legacy viafrancigena)
        let legacyTripTable = Table("viafrancigena_trip")
        try db.run(legacyTripTable.create(ifNotExists: true) { t in
            t.column(trip_id, primaryKey: .autoincrement)
            t.column(trip_start_date)
            t.column(trip_return_date)
            t.column(trip_distance)
            t.column(trip_gain)
            t.column(trip_loss)
            t.column(trip_slope)
            t.column(trip_days)
            t.column(select_trail)
            t.column(trip_title)
            t.column(distance_uom, defaultValue: "Km")
            t.column(temp_uom, defaultValue: "C")
            t.column(weight_uom, defaultValue: "Kg")
            t.column(planning_range, defaultValue: 50.0)
        })
        
        try db.run(planTable.create(ifNotExists: true) { t in
            t.column(plan_id, primaryKey: .autoincrement)
            t.column(plan_date)
            t.column(plan_stop_city)
            t.column(plan_distance)
            t.column(plan_gain)
            t.column(plan_loss)
            t.column(plan_slope)
            t.column(plan_duration)
            t.column(plan_stop_type)
        })
        
        try db.run(mileageTable.create(ifNotExists: true) { t in
            t.column(mileage_id, primaryKey: .autoincrement)
            t.column(mileage_date)
            t.column(mileage_stop_city)
            t.column(mileage_stop_type)
            t.column(mileage_start_time)
            t.column(mileage_stop_time)
            t.column(mileage_actual_distance)
            t.column(mileage_actual_gain)
            t.column(mileage_actual_loss)
            t.column(mileage_actual_slope)
            t.column(mileage_actual_duration)
            t.column(mileage_actual_moving)
            t.column(mileage_actual_pace)
            t.column(mileage_zero_distance)
            t.column(mileage_high_temp)
            t.column(mileage_pilgrims)
            t.column(mileage_note)
        })
        
        try db.run(expenseTable.create(ifNotExists: true) { t in
            t.column(expense_id, primaryKey: .autoincrement)
            t.column(expense_date)
            t.column(expense_stop_city)
            t.column(expense_stop_type)
            t.column(expense_payment)
            t.column(expense_payment_type)
            t.column(expense_category)
            t.column(expense_type)
            t.column(expense_vendor)
            t.column(expense_local_amount)
            t.column(expense_currency)
            t.column(expense_usd_amount) // renamed column
            t.column(expense_note)
        })
    }
    
    // Indexes for performance
    private func createWaypointIndexesIfNeeded(for trail: String) throws {
        guard let db = db else { return }
        let tableName = "\(trail)_waypoints"
        try db.execute("CREATE INDEX IF NOT EXISTS idx_\(tableName)_seq ON \(tableName)(seq);")
        try db.execute("CREATE INDEX IF NOT EXISTS idx_\(tableName)_city ON \(tableName)(hike_city);")
    }
    
    // MARK: - Dynamic Trail Table Creation
    
    func createTrailTablesIfNeeded(for trail: String) throws {
        guard let db = db else { return }
        
        // Waypoints table for this trail
        let trailWaypointsTable = Table("\(trail)_waypoints")
        try db.run(trailWaypointsTable.create(ifNotExists: true) { t in
            t.column(waypoint_id, primaryKey: .autoincrement)
            t.column(waypoint_seq)            // NEW
            t.column(waypoint_latitude)
            t.column(waypoint_longitude)
            t.column(waypoint_elevation)
            t.column(waypoint_distance)
            t.column(waypoint_hike_city)
            t.column(waypoint_gain)
            t.column(waypoint_loss)
            t.column(waypoint_pace_dist)
            t.column(waypoint_pace_gain)
            t.column(waypoint_FME)
            t.column(waypoint_facilities)
            t.column(waypoint_variant_city)
        })
        try createWaypointIndexesIfNeeded(for: trail)
        
        // Trip table for this trail
        let trailTripTable = tripTableFor(trail: trail)
        try db.run(trailTripTable.create(ifNotExists: true) { t in
            t.column(trip_id, primaryKey: .autoincrement)
            t.column(trip_start_date)
            t.column(trip_return_date)
            t.column(trip_distance)
            t.column(trip_gain)
            t.column(trip_loss)
            t.column(trip_slope)
            t.column(trip_days)
            t.column(select_trail)
            t.column(trip_title)
            t.column(distance_uom, defaultValue: "km")
            t.column(temp_uom, defaultValue: "C")
            t.column(weight_uom, defaultValue: "kg")
            t.column(planning_range, defaultValue: 50.0)
        })
        
        print("Trail tables created for: \(trail)")
    }
    
    // MARK: - Transactions & Utilities
    
    func beginTransaction() {
        try? db?.execute("BEGIN IMMEDIATE TRANSACTION;")
    }
    func endTransaction() {
        try? db?.execute("COMMIT;")
    }
    func rollbackTransaction() {
        try? db?.execute("ROLLBACK;")
    }
    
    func clearTrailTables(_ trail: String) {
        guard let db = db else { return }
        let tw = Table("\(trail)_waypoints")
        let ta = Table("\(trail)_attractions")
        let tz = Table("\(trail)_zeros")
        do {
            try db.run(tw.delete())
            try db.run(ta.delete())
            try db.run(tz.delete())
        } catch {
            print("Error clearing \(trail) tables: \(error)")
        }
    }
    
    // MARK: - App Config
    
    func getCurrentTrail() -> String? {
        guard let db = db else { return nil }
        do {
            let q = appConfigTable.filter(app_config_key == "current_trail").limit(1)
            if let row = try db.pluck(q) {
                return row[app_config_value]
            }
        } catch {
            print("Error reading current trail: \(error)")
        }
        return nil
    }
    
    func setCurrentTrail(_ trail: String) {
        guard let db = db else { return }
        do {
            let q = appConfigTable.filter(app_config_key == "current_trail")
            if try db.run(q.update(app_config_value <- trail)) == 0 {
                try db.run(appConfigTable.insert(app_config_key <- "current_trail", app_config_value <- trail))
            }
        } catch {
            print("Error setting current trail: \(error)")
        }
    }
    
    // MARK: - Settings CRUD Operations (unchanged)
    
    func loadTripSettings(for trail: String) -> TripSettings? {
        guard let db = db else { return nil }
        
        do {
            try createTrailTablesIfNeeded(for: trail)
            let tripTable = tripTableFor(trail: trail)
            let query = tripTable.limit(1)
            
            for trip in try db.prepare(query) {
                return TripSettings(
                    selectTrail: trip[select_trail],
                    tripTitle: trip[trip_title],
                    distanceUom: trip[distance_uom],
                    tempUom: trip[temp_uom],
                    weightUom: trip[weight_uom],
                    planningRange: trip[planning_range] ?? 50.0
                )
            }
        } catch {
            print("Error loading trip settings: \(error)")
        }
        
        return nil
    }
    
    func saveTripSettings(_ settings: TripSettings, for trail: String) -> Bool {
        guard let db = db else { return false }
        
        do {
            try createTrailTablesIfNeeded(for: trail)
            let tripTable = tripTableFor(trail: trail)
            
            let count = try db.scalar(tripTable.count)
            
            if count == 0 {
                try db.run(tripTable.insert(
                    select_trail <- settings.selectTrail,
                    trip_title <- settings.tripTitle,
                    distance_uom <- settings.distanceUom,
                    temp_uom <- settings.tempUom,
                    weight_uom <- settings.weightUom,
                    planning_range <- settings.planningRange,
                    trip_start_date <- "",
                    trip_return_date <- "",
                    trip_distance <- 0.0,
                    trip_gain <- 0.0,
                    trip_loss <- 0.0,
                    trip_slope <- 0.0,
                    trip_days <- 0
                ))
            } else {
                try db.run(tripTable.update(
                    select_trail <- settings.selectTrail,
                    trip_title <- settings.tripTitle,
                    distance_uom <- settings.distanceUom,
                    temp_uom <- settings.tempUom,
                    weight_uom <- settings.weightUom,
                    planning_range <- settings.planningRange
                ))
            }
            
            return true
        } catch {
            print("Error saving trip settings: \(error)")
            return false
        }
    }
    
    func updateWaypointPaceFromCity(trail: String, fromCity: String, newPaceDistance: Int, newPaceGain: Int) -> Bool {
        guard let db = db else { return false }
        
        do {
            let trailWaypointsTable = Table("\(trail)_waypoints")
            let cityQuery = trailWaypointsTable.filter(waypoint_hike_city == fromCity).order(waypoint_seq.asc).limit(1)
            
            var startSeq: Int = 0
            for waypoint in try db.prepare(cityQuery) {
                startSeq = waypoint[waypoint_seq]
                break
            }
            let updateQuery = trailWaypointsTable.filter(waypoint_seq >= startSeq)
            try db.run(updateQuery.update(
                waypoint_pace_dist <- newPaceDistance,
                waypoint_pace_gain <- newPaceGain
            ))
            
            print("Updated pace settings from \(fromCity) onwards")
            return true
        } catch {
            print("Error updating waypoint pace: \(error)")
            return false
        }
    }
    
    func getHikingCities(for trail: String) -> [String] {
        guard let db = db else { return [] }
        
        do {
            let trailWaypointsTable = Table("\(trail)_waypoints")
            let query = trailWaypointsTable.filter(waypoint_hike_city != nil)
            var cities: [String] = []
            for waypoint in try db.prepare(query.select(waypoint_hike_city.distinct)) {
                if let city = waypoint[waypoint_hike_city] {
                    cities.append(city)
                }
            }
            return cities.sorted()
        } catch {
            print("Error getting hiking cities: \(error)")
            return []
        }
    }
    
    // MARK: - Reference Data CRUD (enabled-only behavior can be applied in UI)
    
    func getCurrencies() -> [CurrencyItem] {
        guard let db = db else { return [] }
        do {
            var currencies: [CurrencyItem] = []
            for currency in try db.prepare(currencyTable) {
                currencies.append(CurrencyItem(
                    idNo: currency[currency_id],
                    name: currency[currency_name],
                    exchangeRate: currency[currency_exchange_rate],
                    enabled: currency[currency_enabled]
                ))
            }
            return currencies
        } catch {
            print("Error getting currencies: \(error)")
            return []
        }
    }
    
    func addCurrency(name: String, exchangeRate: Double) -> Bool {
        guard let db = db else { return false }
        do {
            try db.run(currencyTable.insert(
                currency_name <- name,
                currency_exchange_rate <- exchangeRate,
                currency_enabled <- true
            ))
            return true
        } catch {
            print("Error adding currency: \(error)")
            return false
        }
    }
    
    func updateCurrencyEnabled(idNo: Int64, enabled: Bool) -> Bool {
        guard let db = db else { return false }
        do {
            let currency = currencyTable.filter(currency_id == idNo)
            try db.run(currency.update(currency_enabled <- enabled))
            return true
        } catch {
            print("Error updating currency enabled status: \(error)")
            return false
        }
    }
    
    func getPaymentTypes() -> [PaymentItem] {
        guard let db = db else { return [] }
        do {
            var payments: [PaymentItem] = []
            for payment in try db.prepare(paymentTable) {
                payments.append(PaymentItem(
                    idNo: payment[payment_id],
                    name: payment[payment_name],
                    paymentType: payment[payment_type_name],
                    enabled: payment[payment_enabled]
                ))
            }
            return payments
        } catch {
            print("Error getting payment types: \(error)")
            return []
        }
    }
    
    func addPayment(name: String, paymentType: String) -> Bool {
        guard let db = db else { return false }
        do {
            try db.run(paymentTable.insert(
                payment_name <- name,
                payment_type_name <- paymentType,
                payment_enabled <- true
            ))
            return true
        } catch {
            print("Error adding payment: \(error)")
            return false
        }
    }
    
    func updatePaymentEnabled(idNo: Int64, enabled: Bool) -> Bool {
        guard let db = db else { return false }
        do {
            let payment = paymentTable.filter(payment_id == idNo)
            try db.run(payment.update(payment_enabled <- enabled))
            return true
        } catch {
            print("Error updating payment enabled status: \(error)")
            return false
        }
    }
    
    func getCategories() -> [CategoryItem] {
        guard let db = db else { return [] }
        do {
            var categories: [CategoryItem] = []
            for category in try db.prepare(categoryTable) {
                categories.append(CategoryItem(
                    idNo: category[category_id],
                    name: category[category_name],
                    categoryType: category[category_type] ?? "Expense",
                    enabled: category[category_enabled]
                ))
            }
            return categories
        } catch {
            print("Error getting categories: \(error)")
            return []
        }
    }
    
    func addCategory(name: String, categoryType: String = "Expense") -> Bool {
        guard let db = db else { return false }
        do {
            try db.run(categoryTable.insert(
                category_name <- name,
                category_type <- categoryType,
                category_enabled <- true
            ))
            return true
        } catch {
            print("Error adding category: \(error)")
            return false
        }
    }
    
    func updateCategoryEnabled(idNo: Int64, enabled: Bool) -> Bool {
        guard let db = db else { return false }
        do {
            let category = categoryTable.filter(category_id == idNo)
            try db.run(category.update(category_enabled <- enabled))
            return true
        } catch {
            print("Error updating category enabled status: \(error)")
            return false
        }
    }
    
    // MARK: - CSV Import Functions
    
    func importWaypointsCSV(from data: String, for trail: String = "viafrancigena") -> Bool {
        guard let db = db else {
            print("Database connection not available")
            return false
        }
        
        do { try createTrailTablesIfNeeded(for: trail) } catch {
            print("Error creating trail tables: \(error)")
            return false
        }
        
        let lines = data.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            print("CSV file appears to be empty or invalid")
            return false
        }
        
        let headerLine = lines[0]
        let headers = headerLine.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        let expectedHeaders = ["latitude", "longitude", "elevation", "distance", "hike_city", "gain", "loss", "pace_dist", "pace_gain", "fme", "facilities"]
        let missingHeaders = expectedHeaders.filter { !headers.contains($0) }
        if !missingHeaders.isEmpty {
            print("Missing required headers: \(missingHeaders)")
            print("Available headers: \(headers)")
            return false
        }
        
        guard let latIndex = headers.firstIndex(of: "latitude"),
              let lngIndex = headers.firstIndex(of: "longitude"),
              let elevIndex = headers.firstIndex(of: "elevation"),
              let distIndex = headers.firstIndex(of: "distance"),
              let cityIndex = headers.firstIndex(of: "hike_city"),
              let gainIndex = headers.firstIndex(of: "gain"),
              let lossIndex = headers.firstIndex(of: "loss"),
              let paceDistIndex = headers.firstIndex(of: "pace_dist"),
              let paceGainIndex = headers.firstIndex(of: "pace_gain"),
              let fmeIndex = headers.firstIndex(of: "fme"),
              let facilitiesIndex = headers.firstIndex(of: "facilities") else {
            print("Could not find all required column indices")
            return false
        }
        
        print("Column mapping successful - expecting \(headers.count) columns per row")
        
        let trailWaypointsTable = Table("\(trail)_waypoints")
        do {
            try db.run(trailWaypointsTable.delete())
            print("Cleared existing waypoints for \(trail)")
        } catch {
            print("Error clearing waypoints: \(error)")
            return false
        }
        
        var importedCount = 0
        var skippedCount = 0
        let totalLines = lines.count - 1
        
        print("Starting import of \(totalLines) waypoint records...")
        beginTransaction()
        defer { endTransaction() }
        
        var seqCounter = 1 // NEW: deterministic sequence
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue }
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            let values = line.components(separatedBy: ",")
            if values.count != headers.count {
                print("Skipping line \(index + 1): wrong column count (\(values.count) vs \(headers.count))")
                skippedCount += 1
                continue
            }
            
            do {
                guard let latitude = Double(values[latIndex].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let longitude = Double(values[lngIndex].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let elevation = Double(values[elevIndex].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let distance = Double(values[distIndex].trimmingCharacters(in: .whitespacesAndNewlines)) else {
                    print("Skipping line \(index + 1): invalid coordinate/elevation/distance data")
                    skippedCount += 1
                    continue
                }
                
                let hike_city_raw = values[cityIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let hike_city = hike_city_raw.isEmpty ? nil : hike_city_raw
                
                let gainString = values[gainIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let lossString = values[lossIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let paceDistString = values[paceDistIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let paceGainString = values[paceGainIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let gain = Double(gainString),
                      let loss = Double(lossString),
                      let pace_dist = Int(paceDistString),
                      let pace_gain = Int(paceGainString) else {
                    print("Skipping line \(index + 1): invalid gain/loss/pace data")
                    print("Values: gain='\(gainString)', loss='\(lossString)', pace_dist='\(paceDistString)', pace_gain='\(paceGainString)'")
                    skippedCount += 1
                    continue
                }
                
                let FME = values[fmeIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let facilities_raw = values[facilitiesIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let facilities = facilities_raw.isEmpty ? nil : facilities_raw
                
                try db.run(trailWaypointsTable.insert(
                    waypoint_seq <- seqCounter,           // NEW
                    waypoint_latitude <- latitude,
                    waypoint_longitude <- longitude,
                    waypoint_elevation <- elevation,
                    waypoint_distance <- distance,
                    waypoint_hike_city <- hike_city,
                    waypoint_gain <- gain,
                    waypoint_loss <- loss,
                    waypoint_pace_dist <- pace_dist,
                    waypoint_pace_gain <- pace_gain,
                    waypoint_FME <- FME,
                    waypoint_facilities <- facilities,
                    waypoint_variant_city <- nil
                ))
                
                seqCounter += 1
                importedCount += 1
                if importedCount <= 3 || importedCount % 1000 == 0 {
                    print("Imported waypoint \(importedCount): \(hike_city ?? "no city") at \(latitude), \(longitude)")
                }
                
            } catch {
                print("Error importing line \(index + 1): \(error)")
                skippedCount += 1
                continue
            }
        }
        
        print("Import completed for \(trail): \(importedCount) records imported, \(skippedCount) skipped")
        return importedCount > 0
    }
    
    func getWaypointCount() -> Int {
        guard let db = db else { return 0 }
        do {
            let count = try db.scalar(waypointsTable.count)
            return count
        } catch {
            print("Error getting waypoint count: \(error)")
            return 0
        }
    }
    
    func getHikingCities() -> [(String, Double, Double, String?)] {
        guard let db = db else { return [] }
        do {
            var cities: [(String, Double, Double, String?)] = []
            for waypoint in try db.prepare(waypointsTable.filter(waypoint_hike_city != nil)) {
                if let cityName = waypoint[waypoint_hike_city] {
                    cities.append((
                        cityName,
                        waypoint[waypoint_distance],
                        waypoint[waypoint_gain],
                        waypoint[waypoint_facilities]
                    ))
                }
            }
            return cities
        } catch {
            print("Error getting hiking cities: \(error)")
            return []
        }
    }
    
    func testConnection() -> Bool { db != nil }
    
    // MARK: - Zeros CRUD Operations
        
    func getZeros(for trail: String) -> [ZeroItem] {
        guard let db = db else { return [] }
        do {
            let trailZerosTable = Table("\(trail)_zeros")
            var zeros: [ZeroItem] = []
            for zero in try db.prepare(trailZerosTable) {
                zeros.append(ZeroItem(
                    idNo: zero[zero_id],
                    city: zero[zero_city]
                ))
            }
            return zeros
        } catch {
            print("Error getting zeros: \(error)")
            return []
        }
    }
    
    func addZero(city: String, for trail: String) -> Bool {
        guard let db = db else { return false }
        do {
            try createTrailTablesIfNeeded(for: trail)
            let trailZerosTable = Table("\(trail)_zeros")
            try db.run(trailZerosTable.insert(
                zero_city <- city
            ))
            return true
        } catch {
            print("Error adding zero: \(error)")
            return false
        }
    }
    
    func updateZero(idNo: Int64, city: String, for trail: String) -> Bool {
        guard let db = db else { return false }
        do {
            let trailZerosTable = Table("\(trail)_zeros")
            let zero = trailZerosTable.filter(zero_id == idNo)
            try db.run(zero.update(zero_city <- city))
            return true
        } catch {
            print("Error updating zero: \(error)")
            return false
        }
    }
    
    // MARK: - Attractions CRUD Operations
    
    func getAttractions(for trail: String) -> [AttractionItem] {
        guard let db = db else { return [] }
        do {
            let trailAttractionsTable = Table("\(trail)_attractions")
            var attractions: [AttractionItem] = []
            for attraction in try db.prepare(trailAttractionsTable) {
                attractions.append(AttractionItem(
                    idNo: attraction[attraction_id],
                    city: attraction[attraction_city],
                    attraction: attraction[self.attraction],
                    map: attraction[attraction_map]
                ))
            }
            return attractions
        } catch {
            print("Error getting attractions: \(error)")
            return []
        }
    }
    
    func getAttractionCities(for trail: String) -> [String] {
        guard let db = db else { return [] }
        do {
            let trailAttractionsTable = Table("\(trail)_attractions")
            var cities: [String] = []
            for attraction in try db.prepare(trailAttractionsTable.select(attraction_city.distinct)) {
                cities.append(attraction[attraction_city])
            }
            return cities.sorted()
        } catch {
            print("Error getting attraction cities: \(error)")
            return []
        }
    }
    
    func addAttraction(city: String, attractionName: String, map: String?, for trail: String) -> Bool {
        guard let db = db else { return false }
        do {
            try createTrailTablesIfNeeded(for: trail)
            let trailAttractionsTable = Table("\(trail)_attractions")
            try db.run(trailAttractionsTable.insert(
                attraction_city <- city,
                attraction <- attractionName,
                attraction_map <- map
            ))
            return true
        } catch {
            print("Error adding attraction: \(error)")
            return false
        }
    }
    
    func updateAttraction(idNo: Int64, city: String, attractionName: String, map: String?, for trail: String) -> Bool {
        guard let db = db else { return false }
        do {
            let trailAttractionsTable = Table("\(trail)_attractions")
            let attractionRecord = trailAttractionsTable.filter(attraction_id == idNo)
            try db.run(attractionRecord.update(
                attraction_city <- city,
                attraction <- attractionName,
                attraction_map <- map
            ))
            return true
        } catch {
            print("Error updating attraction: \(error)")
            return false
        }
    }
    
    // MARK: - Pace Settings Operations
    
    func getPaceSettings(for trail: String, city: String) -> (distance: Int, gain: Int)? {
        guard let db = db else { return nil }
        do {
            let trailWaypointsTable = Table("\(trail)_waypoints")
            let query = trailWaypointsTable.filter(waypoint_hike_city == city).order(waypoint_seq.asc).limit(1)
            for waypoint in try db.prepare(query) {
                return (
                    distance: waypoint[waypoint_pace_dist],
                    gain: waypoint[waypoint_pace_gain]
                )
            }
        } catch {
            print("Error getting pace settings: \(error)")
        }
        return nil
    }
}

// MARK: - Supporting Data Models

struct TripSettings {
    var selectTrail: String
    var tripTitle: String
    var distanceUom: String
    var tempUom: String
    var weightUom: String
    var planningRange: Double
}

struct CurrencyItem: Identifiable {
    let id = UUID()
    var idNo: Int64
    var name: String
    var exchangeRate: Double
    var enabled: Bool
}

struct PaymentItem: Identifiable {
    let id = UUID()
    var idNo: Int64
    var name: String
    var paymentType: String
    var enabled: Bool
}

struct CategoryItem: Identifiable {
    let id = UUID()
    var idNo: Int64
    var name: String
    var categoryType: String
    var enabled: Bool
}

struct ZeroItem: Identifiable {
    let id = UUID()
    var idNo: Int64
    var city: String
}

struct AttractionItem: Identifiable {
    let id = UUID()
    var idNo: Int64
    var city: String
    var attraction: String
    var map: String?
}
