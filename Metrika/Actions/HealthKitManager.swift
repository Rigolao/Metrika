import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    // MARK: - Autorização
    
    /// Pede autorização ao utilizador para ler e escrever os dados de saúde necessários.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // Tipos de dados que queremos ler
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        // Tipos de dados que queremos escrever
        let typesToWrite: Set = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        // Verifica se o HealthKit está disponível no dispositivo.
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { (success, error) in
            completion(success)
        }
    }
    
    // MARK: - Funções de Leitura (Fetch)
    
    /// Busca a última amostra de peso registada.
    func fetchLatestWeight(completion: @escaping (HKQuantitySample?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            completion(samples?.first as? HKQuantitySample)
        }
        
        healthStore.execute(query)
    }
    
    /// Busca o total de água consumida no dia de hoje.
    func fetchTodayWaterIntake(completion: @escaping (Double) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion(0)
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: today, end: nil, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            let totalLitros = result?.sumQuantity()?.doubleValue(for: .liter()) ?? 0
            completion(totalLitros)
        }
        
        healthStore.execute(query)
    }
    
    /// Busca o histórico de amostras de peso dos últimos 30 dias.
    func fetchWeightHistory(completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            completion(samples)
        }
        
        healthStore.execute(query)
    }
    
    /// Busca o histórico de consumo de água dos últimos 30 dias, agrupado por dia.
    func fetchWaterIntakeHistory(completion: @escaping ([Date: Double]) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion([:])
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: today) else {
            completion([:])
            return
        }

        var dailyTotals: [Date: Double] = [:]
        // Inicializa os dias para garantir que os dias sem consumo apareçam
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dailyTotals[date] = 0.0
            }
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                completion(dailyTotals)
                return
            }
            
            // Agrupa as amostras por dia
            for sample in samples {
                let date = calendar.startOfDay(for: sample.startDate)
                let value = sample.quantity.doubleValue(for: .liter())
                dailyTotals[date, default: 0.0] += value
            }
            
            completion(dailyTotals)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Funções de Escrita (Save)

    /// Salva um novo registo de peso no HealthKit.
    func saveWeight(_ weightInKg: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false)
            return
        }
        
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)
        
        healthStore.save(weightSample) { (success, error) in
            completion(success)
        }
    }
    
    /// Salva um novo registo de consumo de água no HealthKit.
    func saveWaterIntake(liters: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion(false)
            return
        }
        
        let waterQuantity = HKQuantity(unit: .liter(), doubleValue: liters)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)
        
        healthStore.save(waterSample) { (success, error) in
            completion(success)
        }
    }
}

