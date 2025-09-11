import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    // MARK: - Autorização
    
    /// Pede autorização ao utilizador para ler e escrever os dados de saúde necessários.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // Adicionamos os novos tipos de dados de atividade que queremos ler
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType()
        ]
        
        // Tipos de dados que queremos escrever
        let typesToWrite: Set<HKSampleType> = [
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
    
    // MARK: - Helper (FUNÇÃO CORRIGIDA)
    
    /// Cria um predicado (filtro) para buscar dados apenas do dia de hoje.
    private func createTodayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
    }
    
    // MARK: - Funções de Peso (sem alterações)
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
    
    // MARK: - Funções de Hidratação (sem alterações)
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
            
            for sample in samples {
                let date = calendar.startOfDay(for: sample.startDate)
                let value = sample.quantity.doubleValue(for: .liter())
                dailyTotals[date, default: 0.0] += value
            }
            
            completion(dailyTotals)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Funções de Atividade
    
    /// Busca o total de calorias ativas queimadas no dia de hoje.
    func fetchTodayActiveEnergy(completion: @escaping (Double) -> Void) {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }

        let predicate = createTodayPredicate()
        let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            let calories = sum.doubleValue(for: .kilocalorie())
            completion(calories)
        }
        healthStore.execute(query)
    }

    /// Busca o total de minutos de exercício no dia de hoje.
    func fetchTodayExerciseTime(completion: @escaping (Double) -> Void) {
        guard let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else {
            completion(0)
            return
        }

        let predicate = createTodayPredicate()
        let query = HKStatisticsQuery(quantityType: exerciseTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            let minutes = sum.doubleValue(for: .minute())
            completion(minutes)
        }
        healthStore.execute(query)
    }

    /// Busca os treinos registrados nos últimos 7 dias.
    func fetchWorkoutsForLastWeek(completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else {
                completion([])
                return
            }
            completion(workouts)
        }
        healthStore.execute(query)
    }
    
    /// **(NOVA FUNÇÃO)** Busca as calorias para um treino específico.
    func fetchEnergyForWorkout(_ workout: HKWorkout, completion: @escaping (Double) -> Void) {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            completion(sum.doubleValue(for: .kilocalorie()))
        }
        healthStore.execute(query)
    }
}

