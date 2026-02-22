@preconcurrency import FirebaseFirestore
import Foundation
import RealmSwift

/// テストデータを作成するマネージャークラス
/// Firebaseの動作確認やアプリのデモンストレーション用のテストデータを生成します
@MainActor
final class TestDataManager {

    static let shared = TestDataManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Public Methods

    /// テストデータを一括作成
    ///
    /// グループ、課題、対策、ノート、メモ、目標のテストデータをRealmに作成します。
    /// このメソッドを呼び出すだけで、すぐにFirebaseの動作確認ができます。
    ///
    /// - Throws: SportsNoteError データ保存に失敗した場合
    ///
    /// # 使用例
    /// ```swift
    /// // 任意の場所で呼び出し可能
    /// Task {
    ///     try await TestDataManager.shared.createTestData()
    /// }
    /// ```
    func createTestData() async throws {
        print("📝 テストデータの作成を開始します...")

        // 1. グループを作成
        let groups = try await createTestGroups()
        print("✅ グループ作成完了: \(groups.count)件")

        // 2. 課題を作成
        let tasks = try await createTestTasks(groups: groups)
        print("✅ 課題作成完了: \(tasks.count)件")

        // 3. 対策を作成
        let measures = try await createTestMeasures(tasks: tasks)
        print("✅ 対策作成完了: \(measures.count)件")

        // 4. ノートを作成
        let notes = try await createTestNotes()
        print("✅ ノート作成完了: \(notes.count)件")

        // 5. メモを作成
        let memos = try await createTestMemos(measures: measures, notes: notes)
        print("✅ メモ作成完了: \(memos.count)件")

        // 6. 目標を作成
        let targets = try await createTestTargets()
        print("✅ 目標作成完了: \(targets.count)件")

        print("🎉 テストデータの作成が完了しました！")
    }

    // MARK: - Private Methods

    /// テストグループを作成
    /// - Returns: 作成したグループの配列
    private func createTestGroups() async throws -> [Group] {
        var groups: [Group] = []

        // グループ1: サーブ（赤）
        let group1 = Group()
        group1.groupID = UUIDGenerator.generateID()
        group1.title = "サーブ"
        group1.color = GroupColor.red.rawValue
        group1.order = 0
        group1.isDeleted = false
        group1.created_at = Date().addingTimeInterval(-86400 * 30)  // 30日前
        group1.updated_at = Date()
        group1.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        try RealmManager.shared.saveItem(group1)
        groups.append(group1)

        // グループ2: レシーブ（青）
        let group2 = Group()
        group2.groupID = UUIDGenerator.generateID()
        group2.title = "レシーブ"
        group2.color = GroupColor.blue.rawValue
        group2.order = 1
        group2.isDeleted = false
        group2.created_at = Date().addingTimeInterval(-86400 * 25)
        group2.updated_at = Date()
        group2.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        try RealmManager.shared.saveItem(group2)
        groups.append(group2)

        // グループ3: スパイク（オレンジ）
        let group3 = Group()
        group3.groupID = UUIDGenerator.generateID()
        group3.title = "スパイク"
        group3.color = GroupColor.orange.rawValue
        group3.order = 2
        group3.isDeleted = false
        group3.created_at = Date().addingTimeInterval(-86400 * 20)
        group3.updated_at = Date()
        group3.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        try RealmManager.shared.saveItem(group3)
        groups.append(group3)

        // グループ4: フィジカル（緑）
        let group4 = Group()
        group4.groupID = UUIDGenerator.generateID()
        group4.title = "フィジカル"
        group4.color = GroupColor.green.rawValue
        group4.order = 3
        group4.isDeleted = false
        group4.created_at = Date().addingTimeInterval(-86400 * 15)
        group4.updated_at = Date()
        group4.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        try RealmManager.shared.saveItem(group4)
        groups.append(group4)

        return groups
    }

    /// テスト課題を作成
    /// - Parameter groups: グループの配列
    /// - Returns: 作成した課題の配列
    private func createTestTasks(groups: [Group]) async throws -> [TaskData] {
        var tasks: [TaskData] = []
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")

        // グループ1の課題
        if groups.count > 0 {
            let task1 = TaskData()
            task1.taskID = UUIDGenerator.generateID()
            task1.userID = userID
            task1.title = "サーブの確率を上げる"
            task1.cause = "トスが安定しないため、コントロールが悪い"
            task1.groupID = groups[0].groupID
            task1.order = 0
            task1.isComplete = false
            task1.isDeleted = false
            task1.created_at = Date().addingTimeInterval(-86400 * 28)
            task1.updated_at = Date()
            try RealmManager.shared.saveItem(task1)
            tasks.append(task1)

            let task2 = TaskData()
            task2.taskID = UUIDGenerator.generateID()
            task2.userID = userID
            task2.title = "ジャンプサーブの威力向上"
            task2.cause = "助走のタイミングとインパクトの強さが足りない"
            task2.groupID = groups[0].groupID
            task2.order = 1
            task2.isComplete = false
            task2.isDeleted = false
            task2.created_at = Date().addingTimeInterval(-86400 * 25)
            task2.updated_at = Date()
            try RealmManager.shared.saveItem(task2)
            tasks.append(task2)
        }

        // グループ2の課題
        if groups.count > 1 {
            let task3 = TaskData()
            task3.taskID = UUIDGenerator.generateID()
            task3.userID = userID
            task3.title = "レシーブの反応速度改善"
            task3.cause = "相手の動きを予測できず、反応が遅れる"
            task3.groupID = groups[1].groupID
            task3.order = 0
            task3.isComplete = false
            task3.isDeleted = false
            task3.created_at = Date().addingTimeInterval(-86400 * 22)
            task3.updated_at = Date()
            try RealmManager.shared.saveItem(task3)
            tasks.append(task3)

            let task4 = TaskData()
            task4.taskID = UUIDGenerator.generateID()
            task4.userID = userID
            task4.title = "低い姿勢でのレシーブ強化"
            task4.cause = "腰が高くなりがちで、安定したレシーブができない"
            task4.groupID = groups[1].groupID
            task4.order = 1
            task4.isComplete = true  // 完了済み
            task4.isDeleted = false
            task4.created_at = Date().addingTimeInterval(-86400 * 20)
            task4.updated_at = Date()
            try RealmManager.shared.saveItem(task4)
            tasks.append(task4)
        }

        // グループ3の課題
        if groups.count > 2 {
            let task5 = TaskData()
            task5.taskID = UUIDGenerator.generateID()
            task5.userID = userID
            task5.title = "クイック攻撃のタイミング"
            task5.cause = "セッターとのタイミングが合わない"
            task5.groupID = groups[2].groupID
            task5.order = 0
            task5.isComplete = false
            task5.isDeleted = false
            task5.created_at = Date().addingTimeInterval(-86400 * 18)
            task5.updated_at = Date()
            try RealmManager.shared.saveItem(task5)
            tasks.append(task5)

            let task6 = TaskData()
            task6.taskID = UUIDGenerator.generateID()
            task6.userID = userID
            task6.title = "コースの打ち分け精度"
            task6.cause = "同じコースに打ちがちで読まれやすい"
            task6.groupID = groups[2].groupID
            task6.order = 1
            task6.isComplete = false
            task6.isDeleted = false
            task6.created_at = Date().addingTimeInterval(-86400 * 15)
            task6.updated_at = Date()
            try RealmManager.shared.saveItem(task6)
            tasks.append(task6)
        }

        // グループ4の課題
        if groups.count > 3 {
            let task7 = TaskData()
            task7.taskID = UUIDGenerator.generateID()
            task7.userID = userID
            task7.title = "ジャンプ力の向上"
            task7.cause = "スクワットなどの基礎筋力が不足している"
            task7.groupID = groups[3].groupID
            task7.order = 0
            task7.isComplete = false
            task7.isDeleted = false
            task7.created_at = Date().addingTimeInterval(-86400 * 12)
            task7.updated_at = Date()
            try RealmManager.shared.saveItem(task7)
            tasks.append(task7)

            let task8 = TaskData()
            task8.taskID = UUIDGenerator.generateID()
            task8.userID = userID
            task8.title = "スタミナ強化"
            task8.cause = "試合後半で動きが鈍くなる"
            task8.groupID = groups[3].groupID
            task8.order = 1
            task8.isComplete = false
            task8.isDeleted = false
            task8.created_at = Date().addingTimeInterval(-86400 * 10)
            task8.updated_at = Date()
            try RealmManager.shared.saveItem(task8)
            tasks.append(task8)
        }

        return tasks
    }

    /// テスト対策を作成
    /// - Parameter tasks: 課題の配列
    /// - Returns: 作成した対策の配列
    private func createTestMeasures(tasks: [TaskData]) async throws -> [Measures] {
        var measuresList: [Measures] = []
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")

        for (taskIndex, task) in tasks.enumerated() {
            // 各課題に2-3個の対策を作成
            let measuresCount = (taskIndex % 2 == 0) ? 2 : 3

            for i in 0..<measuresCount {
                let measures = Measures()
                measures.measuresID = UUIDGenerator.generateID()
                measures.userID = userID
                measures.taskID = task.taskID
                measures.order = i
                measures.isDeleted = false
                measures.created_at = task.created_at.addingTimeInterval(Double(i) * 86400)
                measures.updated_at = Date()

                // タスクに応じた対策内容を設定
                switch taskIndex {
                case 0:  // サーブの確率を上げる
                    measures.title = i == 0 ? "毎日100本トスの練習" : "鏡でフォームを確認する"
                case 1:  // ジャンプサーブの威力向上
                    if i == 0 {
                        measures.title = "助走3歩のリズム練習"
                    } else if i == 1 {
                        measures.title = "インパクト時の体幹を意識"
                    } else {
                        measures.title = "動画でプロのフォーム研究"
                    }
                case 2:  // レシーブの反応速度改善
                    measures.title = i == 0 ? "反応ドリルを毎日5分" : "アイトレーニングを実施"
                case 3:  // 低い姿勢でのレシーブ強化
                    if i == 0 {
                        measures.title = "スクワット姿勢でのパス練習"
                    } else if i == 1 {
                        measures.title = "壁打ち100本"
                    } else {
                        measures.title = "体幹トレーニングを毎日"
                    }
                case 4:  // クイック攻撃のタイミング
                    measures.title = i == 0 ? "セッターとの呼吸合わせ" : "助走のタイミングを固定"
                case 5:  // コースの打ち分け精度
                    if i == 0 {
                        measures.title = "コーンを置いて狙い撃ち練習"
                    } else if i == 1 {
                        measures.title = "手首の使い方を意識"
                    } else {
                        measures.title = "試合映像で相手コート分析"
                    }
                case 6:  // ジャンプ力の向上
                    measures.title = i == 0 ? "週3回のスクワット100回" : "ジャンプトレーニング毎日30回"
                default:  // スタミナ強化
                    if i == 0 {
                        measures.title = "週2回の5kmランニング"
                    } else if i == 1 {
                        measures.title = "インターバルトレーニング"
                    } else {
                        measures.title = "試合を想定した連続練習"
                    }
                }

                try RealmManager.shared.saveItem(measures)
                measuresList.append(measures)
            }
        }

        return measuresList
    }

    /// テストノートを作成
    /// - Returns: 作成したノートの配列
    private func createTestNotes() async throws -> [Note] {
        var notes: [Note] = []
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")

        // 練習ノート1
        let practiceNote1 = Note()
        practiceNote1.noteID = UUIDGenerator.generateID()
        practiceNote1.userID = userID
        practiceNote1.noteType = NoteType.practice.rawValue
        practiceNote1.date = Date().addingTimeInterval(-86400 * 9)  // 9日前
        practiceNote1.weather = Weather.sunny.rawValue
        practiceNote1.temperature = 28
        practiceNote1.condition = "体調良好、モチベーション高い"
        practiceNote1.purpose = "サーブとレシーブの強化"
        practiceNote1.detail = "サーブ100本練習。トスが安定してきた。レシーブは低い姿勢を意識できた。"
        practiceNote1.reflection = "サーブの確率が上がってきた。継続が大事。"
        practiceNote1.isDeleted = false
        practiceNote1.created_at = Date().addingTimeInterval(-86400 * 9)
        practiceNote1.updated_at = Date()
        try RealmManager.shared.saveItem(practiceNote1)
        notes.append(practiceNote1)

        // 練習ノート2
        let practiceNote2 = Note()
        practiceNote2.noteID = UUIDGenerator.generateID()
        practiceNote2.userID = userID
        practiceNote2.noteType = NoteType.practice.rawValue
        practiceNote2.date = Date().addingTimeInterval(-86400 * 7)  // 7日前
        practiceNote2.weather = Weather.cloudy.rawValue
        practiceNote2.temperature = 25
        practiceNote2.condition = "少し疲労感あり"
        practiceNote2.purpose = "レシーブ強化"
        practiceNote2.detail = "反応ドリルと低い姿勢でのパス練習を実施。"
        practiceNote2.reflection = "姿勢を低く保つことで安定感が増した。"
        practiceNote2.isDeleted = false
        practiceNote2.created_at = Date().addingTimeInterval(-86400 * 7)
        practiceNote2.updated_at = Date()
        try RealmManager.shared.saveItem(practiceNote2)
        notes.append(practiceNote2)

        // 練習ノート3
        let practiceNote3 = Note()
        practiceNote3.noteID = UUIDGenerator.generateID()
        practiceNote3.userID = userID
        practiceNote3.noteType = NoteType.practice.rawValue
        practiceNote3.date = Date().addingTimeInterval(-86400 * 5)  // 5日前
        practiceNote3.weather = Weather.sunny.rawValue
        practiceNote3.temperature = 27
        practiceNote3.condition = "コンディション良好"
        practiceNote3.purpose = "スパイクのコース打ち分け"
        practiceNote3.detail = "コーンを置いて狙い撃ち練習を実施。クロスとストレートの打ち分けを重点的に。"
        practiceNote3.reflection = "手首の使い方で変化をつけられることが分かった。"
        practiceNote3.isDeleted = false
        practiceNote3.created_at = Date().addingTimeInterval(-86400 * 5)
        practiceNote3.updated_at = Date()
        try RealmManager.shared.saveItem(practiceNote3)
        notes.append(practiceNote3)

        // 練習ノート4
        let practiceNote4 = Note()
        practiceNote4.noteID = UUIDGenerator.generateID()
        practiceNote4.userID = userID
        practiceNote4.noteType = NoteType.practice.rawValue
        practiceNote4.date = Date().addingTimeInterval(-86400 * 4)  // 4日前
        practiceNote4.weather = Weather.cloudy.rawValue
        practiceNote4.temperature = 24
        practiceNote4.condition = "やや肌寒い"
        practiceNote4.purpose = "クイック攻撃の連携"
        practiceNote4.detail = "セッターとのタイミング合わせを重点的に練習。"
        practiceNote4.reflection = "呼吸が合うようになってきた。継続が重要。"
        practiceNote4.isDeleted = false
        practiceNote4.created_at = Date().addingTimeInterval(-86400 * 4)
        practiceNote4.updated_at = Date()
        try RealmManager.shared.saveItem(practiceNote4)
        notes.append(practiceNote4)

        // 練習ノート5
        let practiceNote5 = Note()
        practiceNote5.noteID = UUIDGenerator.generateID()
        practiceNote5.userID = userID
        practiceNote5.noteType = NoteType.practice.rawValue
        practiceNote5.date = Date().addingTimeInterval(-86400 * 2)  // 2日前
        practiceNote5.weather = Weather.sunny.rawValue
        practiceNote5.temperature = 29
        practiceNote5.condition = "暑いが調子良い"
        practiceNote5.purpose = "フィジカルトレーニング"
        practiceNote5.detail = "スクワット100回、ジャンプトレーニング30回実施。"
        practiceNote5.reflection = "ジャンプ力が少しずつ向上している実感がある。"
        practiceNote5.isDeleted = false
        practiceNote5.created_at = Date().addingTimeInterval(-86400 * 2)
        practiceNote5.updated_at = Date()
        try RealmManager.shared.saveItem(practiceNote5)
        notes.append(practiceNote5)

        // 練習ノート6
        let practiceNote6 = Note()
        practiceNote6.noteID = UUIDGenerator.generateID()
        practiceNote6.userID = userID
        practiceNote6.noteType = NoteType.practice.rawValue
        practiceNote6.date = Date().addingTimeInterval(-86400 * 1)  // 昨日
        practiceNote6.weather = Weather.sunny.rawValue
        practiceNote6.temperature = 30
        practiceNote6.condition = "暑さで少しバテ気味"
        practiceNote6.purpose = "スタミナ強化"
        practiceNote6.detail = "5kmランニングとインターバルトレーニングを実施。"
        practiceNote6.reflection = "スタミナ不足を実感。継続的なトレーニングが必要。"
        practiceNote6.isDeleted = false
        practiceNote6.created_at = Date().addingTimeInterval(-86400 * 1)
        practiceNote6.updated_at = Date()
        try RealmManager.shared.saveItem(practiceNote6)
        notes.append(practiceNote6)

        // 大会ノート1
        let tournamentNote1 = Note()
        tournamentNote1.noteID = UUIDGenerator.generateID()
        tournamentNote1.userID = userID
        tournamentNote1.noteType = NoteType.tournament.rawValue
        tournamentNote1.date = Date().addingTimeInterval(-86400 * 10)  // 10日前
        tournamentNote1.weather = Weather.sunny.rawValue
        tournamentNote1.temperature = 26
        tournamentNote1.condition = "緊張したが集中できた"
        tournamentNote1.target = "サーブの確率80%以上、積極的なスパイク"
        tournamentNote1.consciousness = "ミスを恐れず攻める姿勢"
        tournamentNote1.result = "2セット目までリードしたが、3セット目で逆転負け。サーブ確率は85%達成。"
        tournamentNote1.reflection = "スタミナ切れが敗因。フィジカル強化が急務。"
        tournamentNote1.isDeleted = false
        tournamentNote1.created_at = Date().addingTimeInterval(-86400 * 10)
        tournamentNote1.updated_at = Date()
        try RealmManager.shared.saveItem(tournamentNote1)
        notes.append(tournamentNote1)

        // 大会ノート2
        let tournamentNote2 = Note()
        tournamentNote2.noteID = UUIDGenerator.generateID()
        tournamentNote2.userID = userID
        tournamentNote2.noteType = NoteType.tournament.rawValue
        tournamentNote2.date = Date().addingTimeInterval(-86400 * 2)  // 2日前
        tournamentNote2.weather = Weather.cloudy.rawValue
        tournamentNote2.temperature = 24
        tournamentNote2.condition = "コンディション良好"
        tournamentNote2.target = "クイック攻撃を積極的に、レシーブ安定"
        tournamentNote2.consciousness = "チーム全体の連携を意識"
        tournamentNote2.result = "ストレート勝ち！クイックのタイミングが良く、得点源に。"
        tournamentNote2.reflection = "練習の成果が出た。この調子で継続する。"
        tournamentNote2.isDeleted = false
        tournamentNote2.created_at = Date().addingTimeInterval(-86400 * 2)
        tournamentNote2.updated_at = Date()
        try RealmManager.shared.saveItem(tournamentNote2)
        notes.append(tournamentNote2)

        return notes
    }

    /// テストメモを作成
    /// - Parameters:
    ///   - measures: 対策の配列
    ///   - notes: ノートの配列
    /// - Returns: 作成したメモの配列
    private func createTestMemos(measures: [Measures], notes: [Note]) async throws -> [Memo] {
        var memos: [Memo] = []
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")

        // 練習ノートのみを対象（大会ノートは除外）
        let practiceNotes = notes.filter { $0.noteType == NoteType.practice.rawValue }

        // 各練習ノートに複数のメモを紐づける
        // ノートと対策のマッピング: [ノートインデックス: [対策インデックス, 対策インデックス, ...]]
        let noteMeasuresMap: [Int: [Int]] = [
            0: [0, 1],  // 練習ノート1: サーブ関連の対策2つ
            1: [2, 3, 4],  // 練習ノート2: レシーブ関連の対策3つ
            2: [5, 12],  // 練習ノート3: スパイク関連の対策2つ
            3: [6, 7],  // 練習ノート4: クイック攻撃関連の対策2つ
            4: [10, 11],  // 練習ノート5: ジャンプ力向上の対策2つ
            5: [17, 18, 19],  // 練習ノート6: スタミナ強化の対策3つ
        ]

        // メモの詳細内容
        let memoDetails: [Int: String] = [
            0: "今日は100本達成。トスが安定してきた。",
            1: "鏡でフォーム確認。肘の位置が重要だと気づいた。",
            2: "反応ドリル5分実施。最初は難しかったが慣れてきた。",
            3: "スクワット姿勢でのパス100本。最初は辛かったが慣れてきた。",
            4: "体幹トレーニングを15分実施。バランスが良くなってきた。",
            5: "コーンを使った狙い撃ち練習。精度が上がってきた。",
            6: "セッターとの呼吸合わせ練習。タイミングが掴めてきた。",
            7: "助走のタイミングを固定する練習。安定してきた。",
            10: "スクワット100回完了。フォームを意識した。",
            11: "ジャンプトレーニング30回完了。少しずつ高く跳べるようになってきた。",
            12: "手首の角度を変える練習。コースの打ち分けができるようになってきた。",
            17: "5kmランニング完了。タイムが少し縮まった。",
            18: "インターバルトレーニング実施。心肺機能の向上を感じる。",
            19: "試合形式の連続練習。最後まで動けるようになってきた。",
        ]

        // 各練習ノートにメモを作成
        for (noteIndex, measuresIndices) in noteMeasuresMap {
            guard noteIndex < practiceNotes.count else { continue }
            let note = practiceNotes[noteIndex]

            for measuresIndex in measuresIndices {
                guard measuresIndex < measures.count else { continue }

                let memo = Memo()
                memo.memoID = UUIDGenerator.generateID()
                memo.userID = userID
                memo.measuresID = measures[measuresIndex].measuresID
                memo.noteID = note.noteID
                memo.noteDate = note.date
                memo.isDeleted = false
                memo.created_at = note.created_at
                memo.updated_at = Date()
                memo.detail = memoDetails[measuresIndex] ?? "練習メモ"

                try RealmManager.shared.saveItem(memo)
                memos.append(memo)
            }
        }

        return memos
    }

    /// テスト目標を作成
    /// - Returns: 作成した目標の配列
    private func createTestTargets() async throws -> [Target] {
        var targets: [Target] = []
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // 年間目標1
        let yearlyTarget1 = Target()
        yearlyTarget1.targetID = UUIDGenerator.generateID()
        yearlyTarget1.userID = userID
        yearlyTarget1.title = "全国大会出場"
        yearlyTarget1.year = currentYear
        yearlyTarget1.month = 1
        yearlyTarget1.isYearlyTarget = true
        yearlyTarget1.isDeleted = false
        yearlyTarget1.created_at = Date().addingTimeInterval(-86400 * 60)
        yearlyTarget1.updated_at = Date()
        try RealmManager.shared.saveItem(yearlyTarget1)
        targets.append(yearlyTarget1)

        // 年間目標2
        let yearlyTarget2 = Target()
        yearlyTarget2.targetID = UUIDGenerator.generateID()
        yearlyTarget2.userID = userID
        yearlyTarget2.title = "レギュラー獲得"
        yearlyTarget2.year = currentYear
        yearlyTarget2.month = 1
        yearlyTarget2.isYearlyTarget = true
        yearlyTarget2.isDeleted = false
        yearlyTarget2.created_at = Date().addingTimeInterval(-86400 * 55)
        yearlyTarget2.updated_at = Date()
        try RealmManager.shared.saveItem(yearlyTarget2)
        targets.append(yearlyTarget2)

        // 今月の目標1
        let monthlyTarget1 = Target()
        monthlyTarget1.targetID = UUIDGenerator.generateID()
        monthlyTarget1.userID = userID
        monthlyTarget1.title = "サーブ確率を90%以上にする"
        monthlyTarget1.year = currentYear
        monthlyTarget1.month = currentMonth
        monthlyTarget1.isYearlyTarget = false
        monthlyTarget1.isDeleted = false
        monthlyTarget1.created_at = Date().addingTimeInterval(-86400 * 25)
        monthlyTarget1.updated_at = Date()
        try RealmManager.shared.saveItem(monthlyTarget1)
        targets.append(monthlyTarget1)

        // 今月の目標2
        let monthlyTarget2 = Target()
        monthlyTarget2.targetID = UUIDGenerator.generateID()
        monthlyTarget2.userID = userID
        monthlyTarget2.title = "ジャンプ力を5cm向上させる"
        monthlyTarget2.year = currentYear
        monthlyTarget2.month = currentMonth
        monthlyTarget2.isYearlyTarget = false
        monthlyTarget2.isDeleted = false
        monthlyTarget2.created_at = Date().addingTimeInterval(-86400 * 20)
        monthlyTarget2.updated_at = Date()
        try RealmManager.shared.saveItem(monthlyTarget2)
        targets.append(monthlyTarget2)

        // 今月の目標3
        let monthlyTarget3 = Target()
        monthlyTarget3.targetID = UUIDGenerator.generateID()
        monthlyTarget3.userID = userID
        monthlyTarget3.title = "5kmを25分以内で走る"
        monthlyTarget3.year = currentYear
        monthlyTarget3.month = currentMonth
        monthlyTarget3.isYearlyTarget = false
        monthlyTarget3.isDeleted = false
        monthlyTarget3.created_at = Date().addingTimeInterval(-86400 * 18)
        monthlyTarget3.updated_at = Date()
        try RealmManager.shared.saveItem(monthlyTarget3)
        targets.append(monthlyTarget3)

        // 先月の目標（参考用）
        let previousMonth = currentMonth == 1 ? 12 : currentMonth - 1
        let previousYear = currentMonth == 1 ? currentYear - 1 : currentYear

        let lastMonthTarget = Target()
        lastMonthTarget.targetID = UUIDGenerator.generateID()
        lastMonthTarget.userID = userID
        lastMonthTarget.title = "レシーブの安定性向上"
        lastMonthTarget.year = previousYear
        lastMonthTarget.month = previousMonth
        lastMonthTarget.isYearlyTarget = false
        lastMonthTarget.isDeleted = false
        lastMonthTarget.created_at = Date().addingTimeInterval(-86400 * 40)
        lastMonthTarget.updated_at = Date()
        try RealmManager.shared.saveItem(lastMonthTarget)
        targets.append(lastMonthTarget)

        return targets
    }

    // MARK: - 旧形式テストデータ投入（マイグレーション検証用）

    /// 旧アプリ形式のテストデータを Firebase の旧コレクションに投入する
    /// マイグレーション機能の動作確認に使用。タイトルに [旧データ] を付与して識別しやすくする
    /// - Note: DEBUG ビルドのみ使用を想定
    func createOldFormatTestData() async throws {
        print("📝 旧形式テストデータの投入を開始します...")

        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        let now = getCurrentTimeString()

        // 1. TaskData コレクション（2件）
        // measuresData: [対策タイトル: [[有効性コメント: ノートID(Int)]]]
        // noteID = 1, 2 は NoteData の noteID と対応
        let task1MeasuresData: [String: [[String: Int]]] = [
            "[旧データ] 毎日100本トスの練習": [
                ["トスが安定してきた": 1],
                ["継続できている": 2],
            ],
            "[旧データ] 鏡でフォームを確認する": [
                ["肘の位置を修正できた": 0],
            ],
        ]
        let task2MeasuresData: [String: [[String: Int]]] = [
            "[旧データ] 反応ドリルを毎日5分": [
                ["反応速度が上がってきた": 1],
            ],
        ]

        let oldTask1: [String: Any] = [
            "taskID": 101,
            "userID": userID,
            "taskTitle": "[旧データ] サーブの確率を上げる",
            "taskCause": "トスが安定しないため、コントロールが悪い",
            "taskAchievement": false,
            "order": 0,
            "isDeleted": false,
            "measuresData": task1MeasuresData,
            "measuresPriority": "[旧データ] 毎日100本トスの練習",
            "created_at": now,
            "updated_at": now,
        ]
        let oldTask2: [String: Any] = [
            "taskID": 102,
            "userID": userID,
            "taskTitle": "[旧データ] レシーブの反応速度改善",
            "taskCause": "相手の動きを予測できず、反応が遅れる",
            "taskAchievement": false,
            "order": 1,
            "isDeleted": false,
            "measuresData": task2MeasuresData,
            "measuresPriority": "[旧データ] 反応ドリルを毎日5分",
            "created_at": now,
            "updated_at": now,
        ]

        try await saveOldDocument(collection: "TaskData", documentID: "\(userID)_101", data: oldTask1)
        try await saveOldDocument(collection: "TaskData", documentID: "\(userID)_102", data: oldTask2)
        print("✅ 旧TaskData 投入完了: 2件")

        // 2. TargetData コレクション（3件: 月次2件 + 年間1件）
        // month = 13 は年間目標を示す旧仕様
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        let oldTarget1: [String: Any] = [
            "userID": userID,
            "year": currentYear,
            "month": currentMonth,
            "detail": "[旧データ] 全国大会出場",
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]
        let oldTarget2: [String: Any] = [
            "userID": userID,
            "year": currentYear,
            "month": currentMonth,
            "detail": "[旧データ] サーブ確率90%以上",
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]
        let oldTarget3: [String: Any] = [
            "userID": userID,
            "year": currentYear,
            "month": 13,  // 年間目標
            "detail": "[旧データ] レギュラー獲得",
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        try await saveOldDocument(
            collection: "TargetData",
            documentID: "\(userID)_\(currentYear)_\(currentMonth)_1",
            data: oldTarget1
        )
        try await saveOldDocument(
            collection: "TargetData",
            documentID: "\(userID)_\(currentYear)_\(currentMonth)_2",
            data: oldTarget2
        )
        try await saveOldDocument(
            collection: "TargetData",
            documentID: "\(userID)_\(currentYear)_13",
            data: oldTarget3
        )
        print("✅ 旧TargetData 投入完了: 3件")

        // 3. FreeNoteData コレクション（1件、ドキュメントID = userID）
        let oldFreeNote: [String: Any] = [
            "userID": userID,
            "title": "[旧データ] フリーノート",
            "detail": "旧アプリから引き継いだフリーノートです。マイグレーション検証用データ。",
            "created_at": now,
            "updated_at": now,
        ]
        try await saveOldDocument(collection: "FreeNoteData", documentID: userID, data: oldFreeNote)
        print("✅ 旧FreeNoteData 投入完了: 1件")

        // 4. NoteData コレクション（2件: 練習記録1件 + 大会記録1件）
        // noteID = 1, 2 は TaskData の measuresData の noteID と対応（Memo-Note の紐付け）
        let oldNote1: [String: Any] = [
            "noteID": 1,
            "userID": userID,
            "noteType": "練習記録",
            "year": currentYear,
            "month": currentMonth,
            "date": 15,
            "day": "月",
            "weather": "晴れ",
            "temperature": 28,
            "physicalCondition": "[旧データ] 体調良好、モチベーション高い",
            "purpose": "サーブ練習",
            "detail": "サーブ100本練習。トスが安定してきた。",
            "target": "",
            "consciousness": "",
            "result": "",
            "reflection": "継続が大事。",
            "taskTitle": ["[旧データ] サーブの確率を上げる"],
            "measuresTitle": ["[旧データ] 毎日100本トスの練習"],
            "measuresEffectiveness": ["トスが安定してきた"],
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]
        let oldNote2: [String: Any] = [
            "noteID": 2,
            "userID": userID,
            "noteType": "大会記録",
            "year": currentYear,
            "month": currentMonth,
            "date": 20,
            "day": "土",
            "weather": "くもり",
            "temperature": 24,
            "physicalCondition": "[旧データ] 少し緊張気味",
            "purpose": "",
            "detail": "",
            "target": "サーブ確率80%以上",
            "consciousness": "ミスを恐れず攻める",
            "result": "2セット先取で勝利。サーブ確率85%達成。",
            "reflection": "練習の成果が出た。",
            "taskTitle": [],
            "measuresTitle": [],
            "measuresEffectiveness": [],
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        try await saveOldDocument(
            collection: "NoteData",
            documentID: "\(userID)_1",
            data: oldNote1
        )
        try await saveOldDocument(
            collection: "NoteData",
            documentID: "\(userID)_2",
            data: oldNote2
        )
        print("✅ 旧NoteData 投入完了: 2件")

        print("🎉 旧形式テストデータの投入が完了しました！")
        print("ℹ️ アプリを再起動すると MigrationManager が自動的にデータを変換します")
    }

    /// 旧コレクションにドキュメントを保存するヘルパー
    private func saveOldDocument(collection: String, documentID: String, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(collection).document(documentID)
                .setData(data) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    /// 現在時刻を文字列で返す（旧アプリの形式に合わせる）
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}
