//
//  ViewController.swift
//  KanjiStudy
//
//  Created by Martin on 2/27/22.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    static let showHiraganaQuizSegueIdentifier = "ShowHiraganaQuizSegue"
    static let showKatakanaQuizSegueIdentifier = "ShowKatakanaQuizSegue"
    static let showEnglishQuizSegueIdentifier = "ShowEnglishQuizSegue"
    
    var kanjiListOriginal = [
        Kanji(character: "日", onyomiReadings: "ニチ, ジツ", kunyomiReadings: "ひ, び", englishMeanings: "sun, day", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "国", onyomiReadings: "コク", kunyomiReadings: "くに", englishMeanings: "country", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "年", onyomiReadings: "ネン", kunyomiReadings: "とし", englishMeanings: "year", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "中", onyomiReadings: "チュウ", kunyomiReadings: "なか, うち", englishMeanings: "in, inside, middle, center", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "月", onyomiReadings: "ゲツ, カツ", kunyomiReadings: "つき", englishMeanings: "moon, month", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "時", onyomiReadings: "ジ", kunyomiReadings: "とき, どき", englishMeanings: "time, hour", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "金", onyomiReadings: "キン, コン, ゴン", kunyomiReadings: "かな, かね, がね", englishMeanings: "gold", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "前", onyomiReadings: "ゼン", kunyomiReadings: "まえ", englishMeanings: "in front, before", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "学", onyomiReadings: "ガク", kunyomiReadings: "まなぶ", englishMeanings: "study", correctCount: 0, totalCount: 0, correctPercent: 0),
        Kanji(character: "今", onyomiReadings: "コン, キン", kunyomiReadings: "いま", englishMeanings: "now", correctCount: 0, totalCount: 0, correctPercent: 0)
    ]
    
    var kanjiList: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
              return
          }
          
          let managedContext =
            appDelegate.persistentContainer.viewContext
          
          //2
          let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "KanjiData")
          
          //3
          do {
            let kanjiDataList = try managedContext.fetch(fetchRequest)
              // TODO: This is used to delete existing data, remove if not needed
//              for kanji in kanjiDataList {
//                  managedContext.delete(kanji)
//              }
//              try managedContext.save()
              if kanjiDataList.count == 0 {
                  // TODO: modify this to get from json file instead of a hardcoded array of values(which is kanjiListOriginal)
                  readJsonFile()
//                  for kanji in kanjiListOriginal {
//                      save(kanjiDataOriginal: kanji)
//                  }
              }
          } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
          }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showHiraganaQuizSegueIdentifier,
           let destination = segue.destination as? QuizViewController {
            destination.configure(quizType: "Kunyomi")
        } else if segue.identifier == Self.showKatakanaQuizSegueIdentifier,
           let destination = segue.destination as? QuizViewController {
            destination.configure(quizType: "Onyomi")
        } else if segue.identifier == Self.showEnglishQuizSegueIdentifier,
           let destination = segue.destination as? QuizViewController {
            destination.configure(quizType: "English")
        }
    }
    
    func save(kanjiDataOriginal: Kanji) {
      
      guard let appDelegate =
        UIApplication.shared.delegate as? AppDelegate else {
        return
      }
      
      // 1
      let managedContext =
        appDelegate.persistentContainer.viewContext
      
      // 2
      let entity =
        NSEntityDescription.entity(forEntityName: "KanjiData",
                                   in: managedContext)!
      
      let kanji = NSManagedObject(entity: entity,
                                   insertInto: managedContext)
      
      // 3
        kanji.setValue(kanjiDataOriginal.character, forKeyPath: "character")
        kanji.setValue(kanjiDataOriginal.englishMeanings, forKeyPath: "englishMeanings")
        kanji.setValue(kanjiDataOriginal.onyomiReadings, forKeyPath: "onyomiReadings")
        kanji.setValue(kanjiDataOriginal.kunyomiReadings, forKeyPath: "kunyomiReadings")
        kanji.setValue(kanjiDataOriginal.correctCount, forKeyPath: "correctCount")
        kanji.setValue(kanjiDataOriginal.totalCount, forKeyPath: "totalCount")
        kanji.setValue(kanjiDataOriginal.correctPercent, forKeyPath: "correctPercent")
      
      // 4
      do {
        try managedContext.save()
        kanjiList.append(kanji)
      } catch let error as NSError {
        print("Could not save. \(error), \(error.userInfo)")
      }
    }
    
    func readJsonFile() {
        if let path = Bundle.main.path(forResource: "kanji_data", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                for jsonDictionary in jsonResult as! NSArray? ?? []{
                    let kanjiItem = jsonDictionary as? Dictionary<String, String>
                    let kanjiToAdd = Kanji(character: kanjiItem!["character"] as! String, onyomiReadings: kanjiItem?["onyomi"] ?? "", kunyomiReadings: kanjiItem?["kunyomi"] ?? "", englishMeanings: kanjiItem!["meanings"] as! String, correctCount: 0, totalCount: 0, correctPercent: 0)
                    save(kanjiDataOriginal: kanjiToAdd)
                }
              } catch {
                   // handle error
              }
        }
    }


}

