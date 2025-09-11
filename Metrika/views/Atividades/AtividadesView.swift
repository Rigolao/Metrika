import SwiftUI
import HealthKit

struct AtividadesView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    @State private var exerciseMinutes: Double = 0
    @State private var activeCalories: Double = 0
    @State private var workouts: [HKWorkout] = []
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Cards de Resumo
                    HStack(spacing: 15) {
                        SummaryCard(title: "Minutos", value: "\(Int(exerciseMinutes))", unit: "min", icon: "flame.fill", color: .orange)
                        SummaryCard(title: "Calorias", value: "\(Int(activeCalories))", unit: "kcal", icon: "heart.fill", color: .red)
                    }
                    
                    // Lista de Atividades
                    VStack(alignment: .leading) {
                        Text("Atividades da Semana")
                            .font(.title2).fontWeight(.semibold)
                        
                        if workouts.isEmpty {
                            Text("Nenhuma atividade registrada na última semana.")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(workouts, id: \.uuid) { workout in
                                    // Passamos o gestor para a linha do treino
                                    WorkoutRow(workout: workout, healthKitManager: healthKitManager)
                                    if workout.uuid != workouts.last?.uuid {
                                        Divider().padding(.leading)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Atividade")
        .onAppear(perform: carregarDados)
    }
    
    private func carregarDados() {
        healthKitManager.requestAuthorization { success in
            if success {
                healthKitManager.fetchTodayExerciseTime { minutes in
                    DispatchQueue.main.async { self.exerciseMinutes = minutes }
                }
                
                healthKitManager.fetchTodayActiveEnergy { calories in
                    DispatchQueue.main.async { self.activeCalories = calories }
                }
                
                healthKitManager.fetchWorkoutsForLastWeek { workouts in
                    DispatchQueue.main.async { self.workouts = workouts }
                }
            }
        }
    }
}

// MARK: - Componentes da View

struct WorkoutRow: View {
    let workout: HKWorkout
    let healthKitManager: HealthKitManager // Recebe o gestor
    
    // Estado para guardar as calorias buscadas
    @State private var caloriesBurned: Double? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: workout.workoutActivityType.icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(workout.workoutActivityType.name)
                    .font(.headline)
                Text(workout.endDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatDuration(workout.duration))
                    .font(.headline)
                // Mostra as calorias quando estiverem carregadas
                if let calories = caloriesBurned {
                    Text("\(Int(calories)) kcal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    // Mostra um indicador enquanto carrega
                    ProgressView()
                        .frame(height: 15)
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            // Busca as calorias quando a linha aparece
            healthKitManager.fetchEnergyForWorkout(workout) { calories in
                DispatchQueue.main.async {
                    self.caloriesBurned = calories
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

// MARK: - Extensões
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Corrida"
        case .walking: return "Caminhada"
        case .cycling: return "Ciclismo"
        case .traditionalStrengthTraining: return "Musculação"
        case .highIntensityIntervalTraining: return "HIIT"
        case .swimming: return "Natação"
        case .yoga: return "Yoga"
        default: return "Outro Treino"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .highIntensityIntervalTraining: return "metronome.fill"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        default: return "figure.mixed.cardio"
        }
    }
}


struct AtividadesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AtividadesView()
        }
    }
}

