import Foundation
import HealthKit

class HealthKitManager {
    
    let store = HKHealthStore()
    
    let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    ]
    
    let typesToWrite: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    ]
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        store.requestAuthorization(toShare: typesToWrite, read: typesToRead) { (success, error) in
            if let error = error {
                print("Erro ao pedir autorização para o HealthKit: \(error.localizedDescription)")
            }
            completion(success)
        }
    }
    
    // MARK: - Funções de Leitura de Dados
    
    /// Busca a amostra de peso mais recente registada no HealthKit.
    func fetchLatestWeight(completion: @escaping (HKQuantitySample?) -> Void) {
        // 1. Define o tipo de dado que queremos: massa corporal (peso).
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        // 2. Define a ordem de ordenação: o mais recente primeiro.
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // 3. Cria a query para buscar apenas 1 resultado, ordenado pelo mais recente.
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Erro ao buscar o peso: \(error.localizedDescription)")
                completion(nil)
                return
            }
            // 4. Retorna o primeiro resultado encontrado (que será o mais recente).
            completion(samples?.first as? HKQuantitySample)
        }
        
        // 5. Executa a query.
        store.execute(query)
    }
    
    /// Soma toda a água registada no dia de hoje.
    func fetchTodayWaterIntake(completion: @escaping (Double) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion(0)
            return
        }

        let calendar = Calendar.current
        // Define o intervalo de tempo: do início do dia de hoje até agora.
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // Cria uma query de estatística para somar todos os valores.
        let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            if let error = error {
                print("Erro ao buscar a ingestão de água: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            // Pega a soma total.
            guard let sum = result?.sumQuantity() else {
                completion(0)
                return
            }
            
            // Retorna o valor em litros.
            completion(sum.doubleValue(for: .liter()))
        }

        store.execute(query)
    }
    
    // MARK: - Funções de Escrita de Dados
    
    /// Salva uma nova amostra de peso no HealthKit.
    func saveWeight(_ weightInKg: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            print("Tipo de dado de massa corporal não está disponível.")
            completion(false)
            return
        }
        
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)
        
        store.save(weightSample) { (success, error) in
            if let error = error {
                print("Erro ao salvar o peso: \(error.localizedDescription)")
            }
            // Informa a UI se o dado foi salvo com sucesso.
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}

