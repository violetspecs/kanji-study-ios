//
//  QuizViewController.swift
//  KanjiStudy
//
//  Created by Martin on 2/27/22.
//

import UIKit
import CoreData

class QuizViewController: UIViewController {
    let buttonFont = UIFont.systemFont(ofSize: 18)
    
    // TODO: Check if this array has same function with objectStoreMapping dictionary
    var kanjiList: [Kanji] = []
    
    var shuffledKanjiList: [Kanji] = []
    var objectStoreMapping: [String: NSManagedObject] = [:]
    
    var currentQuestion = 0
    var correctAnswerPosition = 0
    var score = 0
    var kanjiToUpdate = ""
    
    @IBOutlet var kanjiLabel: UILabel!
    @IBOutlet var answer1Button: UIButton!
    @IBOutlet var answer2Button: UIButton!
    @IBOutlet var answer3Button: UIButton!
    @IBOutlet var answer4Button: UIButton!
    @IBOutlet var isCorrectLabel: UILabel!
    @IBOutlet var tryAgainButton: UIButton!
    var quizText = "Sample"
    func configure(quizType: String) {
        quizText = quizType
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        startQuiz()
    }
    
    func updateAnswerButtons(kanjiList: [Kanji], quizText: String) {
        var displayText: [NSAttributedString] = []
        for i in 0...3 {
            if quizText == "Kunyomi" {
                displayText.append(formatButtonText(buttonText: kanjiList[i].kunyomiReadings))
            } else if quizText == "Onyomi" {
                displayText.append(formatButtonText(buttonText: kanjiList[i].onyomiReadings))
            } else {
                displayText.append(formatButtonText(buttonText: kanjiList[i].englishMeanings))
            }
        }
        answer1Button.setAttributedTitle(displayText[0], for: UIControl.State.normal)
        answer2Button.setAttributedTitle(displayText[1], for: UIControl.State.normal)
        answer3Button.setAttributedTitle(displayText[2], for: UIControl.State.normal)
        answer4Button.setAttributedTitle(displayText[3], for: UIControl.State.normal)
    }
    
    func formatButtonText(buttonText: String) -> NSAttributedString {
        return NSAttributedString(string: buttonText, attributes: [NSAttributedString.Key.font: buttonFont])
    }
    
    func getQuestion() {
        guard currentQuestion < shuffledKanjiList.count else {
            currentQuestion = currentQuestion + 1
            kanjiLabel.text = "End"
            // TODO: submit answers
            
            isCorrectLabel.text = "Score: \(score)/\(shuffledKanjiList.count)"
            tryAgainButton.isHidden = false
            return
        }
        var choices: [Kanji] = []
        let correctAnswer: Kanji = shuffledKanjiList[currentQuestion]
        var correctAnswerRemovedList: [Kanji] = shuffledKanjiList // is this copy or reference?? looks like copy because array is a struct which is a value type
        correctAnswerRemovedList.remove(at: currentQuestion)
        // randomize the other kanji
        correctAnswerRemovedList.shuffle()
        for i in 0...2 {
            choices.append(correctAnswerRemovedList[i])
        }
        
        correctAnswerPosition = Int.random(in: 0..<4)
        kanjiLabel.text = correctAnswer.character
        kanjiToUpdate = correctAnswer.character // used to store which kanji to update in objectStoreMapping array TODO: maybe find a better way to do this
        choices.shuffle()
        choices.insert(correctAnswer, at: correctAnswerPosition)
        updateAnswerButtons(kanjiList: choices, quizText: quizText)
        currentQuestion = currentQuestion + 1
    }
    
    func submitResults() {
        // TODO: add functionality to submit quiz results only at end of quiz
    }
    
    func startQuiz() {
        kanjiList = []
        shuffledKanjiList = []
        objectStoreMapping = [:]
        currentQuestion = 0
        correctAnswerPosition = 0
        score = 0
        kanjiToUpdate = ""
        
        resetUiDisplay()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "KanjiData")
        do {
            if quizText == "Kunyomi" {
                fetchRequest.predicate = NSPredicate(format: "kunyomiReadings != ''")
            } else if quizText == "Onyomi" {
                fetchRequest.predicate = NSPredicate(format: "onyomiReadings != ''")
            } else {
                fetchRequest.predicate = NSPredicate(format: "englishMeanings != ''")
            }
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "correctPercent", ascending: true)]
            let kanjiDataList = try managedContext.fetch(fetchRequest)
            for kanji in kanjiDataList {
                let newKanji = Kanji(character: kanji.value(forKeyPath: "character") as! String,
                                       onyomiReadings: kanji.value(forKeyPath: "onyomiReadings") as! String,
                                       kunyomiReadings: kanji.value(forKeyPath: "kunyomiReadings") as! String,
                                       englishMeanings: kanji.value(forKeyPath: "englishMeanings") as! String, correctCount: kanji.value(forKeyPath: "correctCount") as! Int, totalCount: kanji.value(forKeyPath: "totalCount") as! Int, correctPercent: kanji.value(forKeyPath: "correctPercent") as! Int)
                kanjiList.append(newKanji)
                objectStoreMapping[newKanji.character] = kanji // stores the object to be updated by core data on submit of quiz results
                
                  // TODO: Delete or comment if needed, only used to reset scores
//                  kanji.setValue(0, forKey: "correctCount")
//                  kanji.setValue(0, forKey: "totalCount")
//                  kanji.setValue(0, forKey: "correctPercent")
//                  do {
//                      try managedContext.save()
//                  }
//                  catch let error as NSError {
//                      print("Could not save. \(error), \(error.userInfo)")
//                  }
                
            }
              // Get the most frequently gotten wrong kanji TODO: maybe convert into a function?
            shuffledKanjiList = kanjiList[...9].shuffled()
            getQuestion()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func resetUiDisplay() {
        tryAgainButton.isHidden = true
        isCorrectLabel.text = ""
    }
    
    func updateObjectStoreMapping(isCorrect: Bool) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
              return
          }
          
          let managedContext =
            appDelegate.persistentContainer.viewContext
        let coreDataKanji = objectStoreMapping[kanjiToUpdate]
        let currentCorrectCount = coreDataKanji?.value(forKeyPath: "correctCount") as! Int
        let currentTotalCount = coreDataKanji?.value(forKeyPath: "totalCount") as! Int
        var newCorrectCount = currentCorrectCount
        let newTotalCount = currentTotalCount + 1
        
        if isCorrect {
            newCorrectCount = newCorrectCount + 1
            coreDataKanji!.setValue(newCorrectCount, forKey: "correctCount")
        }
        coreDataKanji!.setValue(newTotalCount, forKey: "totalCount")
        
        let newCorrectPercent = Int((Double(newCorrectCount) / Double(newTotalCount)) * 100)
        // do not update correct percent if total times answered is 5 or less since that kanji is still being learnt
        if newTotalCount > 5 {
            coreDataKanji!.setValue(newCorrectPercent, forKey: "correctPercent")
        }
        
        do {
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    @IBAction func answer1Selected(_ sender: Any) {
        if currentQuestion <= shuffledKanjiList.count {
            if correctAnswerPosition == 0 {
                isCorrectLabel.text = "Correct"
                score += 1
                updateObjectStoreMapping(isCorrect: true)
            } else {
                isCorrectLabel.text = "Wrong"
                updateObjectStoreMapping(isCorrect: false)
            }
            getQuestion()
        }
        
    }
    @IBAction func answer2Selected(_ sender: Any) {
        if currentQuestion <= shuffledKanjiList.count {
            if correctAnswerPosition == 1 {
                isCorrectLabel.text = "Correct"
                score += 1
                updateObjectStoreMapping(isCorrect: true)
            } else {
                isCorrectLabel.text = "Wrong"
                updateObjectStoreMapping(isCorrect: false)
            }
            getQuestion()
        }
    }
    @IBAction func answer3Selected(_ sender: Any) {
        if currentQuestion <= shuffledKanjiList.count {
            if correctAnswerPosition == 2 {
                isCorrectLabel.text = "Correct"
                score += 1
                updateObjectStoreMapping(isCorrect: true)
            } else {
                isCorrectLabel.text = "Wrong"
                updateObjectStoreMapping(isCorrect: false)
            }
            getQuestion()
        }
    }
    @IBAction func answer4Selected(_ sender: Any) {
        if currentQuestion <= shuffledKanjiList.count {
            if correctAnswerPosition == 3 {
                isCorrectLabel.text = "Correct"
                score += 1
                updateObjectStoreMapping(isCorrect: true)
            } else {
                isCorrectLabel.text = "Wrong"
                updateObjectStoreMapping(isCorrect: false)
            }
            getQuestion()
        }
    }
    @IBAction func tryAgainButtonTapped(_ sender: Any) {
        startQuiz()
    }
}

