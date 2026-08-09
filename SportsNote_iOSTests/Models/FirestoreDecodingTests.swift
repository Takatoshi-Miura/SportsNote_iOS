//
//  FirestoreDecodingTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/03.
//

import FirebaseFirestore
import Foundation
import Testing

@testable import SportsNote_iOS

/// issue #110: FirebaseManagerのgetAllXxx群で重複していたFirestoreデコード処理を
/// 各モデルの`convenience init?(firestoreData:)`に集約したことを検証するテスト
@Suite("Firestore Decoding Tests")
struct FirestoreDecodingTests {

    // MARK: - Group

    @Test("Group(firestoreData:) - 必須フィールドが揃っていれば生成できる")
    func group_decodesWhenAllFieldsPresent() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "groupID": "group1",
            "title": "テストグループ",
            "color": 2,
            "order": 3,
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        let group = Group(firestoreData: data)

        #expect(group != nil)
        #expect(group?.userID == "user1")
        #expect(group?.groupID == "group1")
        #expect(group?.title == "テストグループ")
        #expect(group?.color == 2)
        #expect(group?.order == 3)
        #expect(group?.isDeleted == false)
    }

    @Test("Group(firestoreData:) - 必須フィールドが欠落していればnilを返す")
    func group_returnsNilWhenFieldMissing() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "groupID": "group1",
            "title": "テストグループ",
            "color": 2,
            // "order" 欠落
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        #expect(Group(firestoreData: data) == nil)
    }

    // MARK: - TaskData

    @Test("TaskData(firestoreData:) - 必須フィールドが揃っていれば生成できる")
    func taskData_decodesWhenAllFieldsPresent() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "taskID": "task1",
            "groupID": "group1",
            "title": "テスト課題",
            "cause": "原因",
            "order": 1,
            "isComplete": false,
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        let task = TaskData(firestoreData: data)

        #expect(task != nil)
        #expect(task?.taskID == "task1")
        #expect(task?.groupID == "group1")
        #expect(task?.cause == "原因")
    }

    @Test("TaskData(firestoreData:) - 必須フィールドが欠落していればnilを返す")
    func taskData_returnsNilWhenFieldMissing() {
        let data: [String: Any] = [
            "userID": "user1",
            "taskID": "task1",
        ]

        #expect(TaskData(firestoreData: data) == nil)
    }

    // MARK: - Measures

    @Test("Measures(firestoreData:) - 必須フィールドが揃っていれば生成できる")
    func measures_decodesWhenAllFieldsPresent() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "measuresID": "measures1",
            "taskID": "task1",
            "title": "テスト対策",
            "order": 0,
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        let measures = Measures(firestoreData: data)

        #expect(measures != nil)
        #expect(measures?.measuresID == "measures1")
        #expect(measures?.taskID == "task1")
    }

    @Test("Measures(firestoreData:) - 必須フィールドが欠落していればnilを返す")
    func measures_returnsNilWhenFieldMissing() {
        let data: [String: Any] = [
            "userID": "user1"
        ]

        #expect(Measures(firestoreData: data) == nil)
    }

    // MARK: - Memo

    @Test("Memo(firestoreData:) - 必須フィールドが揃っていれば生成できる")
    func memo_decodesWhenAllFieldsPresent() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "memoID": "memo1",
            "noteID": "note1",
            "measuresID": "measures1",
            "detail": "詳細",
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        let memo = Memo(firestoreData: data)

        #expect(memo != nil)
        #expect(memo?.memoID == "memo1")
        #expect(memo?.detail == "詳細")
    }

    @Test("Memo(firestoreData:) - 必須フィールドが欠落していればnilを返す")
    func memo_returnsNilWhenFieldMissing() {
        let data: [String: Any] = [
            "userID": "user1"
        ]

        #expect(Memo(firestoreData: data) == nil)
    }

    // MARK: - Target

    @Test("Target(firestoreData:) - 必須フィールドが揃っていれば生成できる")
    func target_decodesWhenAllFieldsPresent() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "targetID": "target1",
            "title": "テスト目標",
            "year": 2026,
            "month": 8,
            "isYearlyTarget": true,
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
        ]

        let target = Target(firestoreData: data)

        #expect(target != nil)
        #expect(target?.targetID == "target1")
        #expect(target?.isYearlyTarget == true)
    }

    @Test("Target(firestoreData:) - 必須フィールドが欠落していればnilを返す")
    func target_returnsNilWhenFieldMissing() {
        let data: [String: Any] = [
            "userID": "user1"
        ]

        #expect(Target(firestoreData: data) == nil)
    }

    // MARK: - Note

    @Test("Note(firestoreData:) - 必須フィールドが揃っていれば生成できる")
    func note_decodesWhenAllFieldsPresent() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "noteID": "note1",
            "noteType": 1,
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
            "title": "",
            "date": now,
            "weather": 0,
            "temperature": 20,
            "condition": "晴れ",
            "reflection": "振り返り",
            "purpose": "目的",
            "detail": "詳細",
            "target": "目標",
            "consciousness": "意識点",
            "result": "結果",
        ]

        let note = Note(firestoreData: data)

        #expect(note != nil)
        #expect(note?.noteID == "note1")
        #expect(note?.noteType == 1)
        #expect(note?.condition == "晴れ")
        #expect(note?.result == "結果")
    }

    @Test("Note(firestoreData:) - 必須フィールドが欠落していればnilを返す")
    func note_returnsNilWhenFieldMissing() {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "userID": "user1",
            "noteID": "note1",
            "noteType": 1,
            "isDeleted": false,
            "created_at": now,
            "updated_at": now,
                // "title" 以降のフィールドが欠落
        ]

        #expect(Note(firestoreData: data) == nil)
    }
}
