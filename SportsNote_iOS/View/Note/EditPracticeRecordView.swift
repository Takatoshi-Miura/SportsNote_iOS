import SwiftUI

struct EditPracticeRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var notes: String = ""
    
    var onSave: (PracticeRecord) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("種目名", text: $exerciseName)
                    TextField("セット数", text: $sets)
                        .keyboardType(.numberPad)
                    TextField("回数", text: $reps)
                        .keyboardType(.numberPad)
                    TextField("重量 (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("練習記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let record = PracticeRecord(
                            exerciseName: exerciseName,
                            sets: Int(sets) ?? 0,
                            reps: Int(reps) ?? 0,
                            weight: Double(weight) ?? 0.0,
                            notes: notes
                        )
                        onSave(record)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PracticeRecord {
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double
    var notes: String
}