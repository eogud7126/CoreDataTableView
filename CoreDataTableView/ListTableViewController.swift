//
//  ListTableViewController.swift
//  CoreDataTableView
//
//  Created by USER on 16/07/2020.
//  Copyright © 2020 USER. All rights reserved.
//

import UIKit
import CoreData


class ListTableViewController: UITableViewController {

    
    
    //MARK: Properties
    lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        
        //네비게이션 오른쪽 위에 추가 버튼 구현
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
        self.navigationItem.rightBarButtonItem = addBtn
        
        
        
    }

    
    @objc func add(_ sender: Any){
        let alert = UIAlertController(title: "게시글 등록", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: {$0.placeholder = "제목"})
        alert.addTextField(configurationHandler: {$0.placeholder = "내용"})
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default){(_) in
            guard let title = alert.textFields?.first?.text, let contents = alert.textFields?.last?.text else{
                return
            }
            
            //값을 저장, 성공이면 테이블 리로드
            if self.save(title: title, contents: contents) == true {
                self.tableView.reloadData()
            }
        })
        self.present(alert, animated: false)
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.list.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //데이터 가져오기
        let record = self.list[indexPath.row]
        let title = record.value(forKey: "title") as? String
        let contents = record.value(forKey: "contents") as? String
        
        //셀을 생성하고 대입
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = contents
        
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let object = self.list[indexPath.row]
        
        if self.delete(object: object){
            //코어 데이터에서 삭제되면 배열 목록과 테이블 뷰의 행도 삭제
            self.list.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //선택된 행에 해당하는 데이터 가져옴
        let object = self.list[indexPath.row]
        let title = object.value(forKey: "title") as? String
        let contents = object.value(forKey: "contents") as? String
        
        let alert = UIAlertController(title: "게시글 수정", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: {$0.text = title})
        alert.addTextField(configurationHandler: {$0.text = contents})
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { (_) in
            guard let title = alert.textFields?.first?.text, let contents = alert.textFields?.last?.text else{
                return
            }
            
            if self.edit(object: object, title: title, contents: contents) == true {
//                self.tableView.reloadData()
                
                
                //셀의 내용을 직접 수정
                let cell = self.tableView.cellForRow(at: indexPath)
                cell?.textLabel?.text = title
                cell?.detailTextLabel?.text = contents
                
                //수정된 셀을 첫 번째 행으로 이동
                let firstIndexPath = IndexPath(item: 0, section: 0)
                //UI가 reload하는것보다 더 부드러워지는 듯함
                self.tableView.moveRow(at: indexPath, to: firstIndexPath)
            }
            
        })
        self.present(alert, animated: false)
    }
    //MARK: Core Data
    
    
    func fetch() -> [NSManagedObject]{
        //앱 델리게이트 객체 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
        //요청 객체 생성
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        
        //정렬 속성 설정
        let sort = NSSortDescriptor(key: "regdate", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        
        //데이터 가져오기
        let result = try! context.fetch(fetchRequest)
        
        return result
    }
    
    func save(title: String, contents: String) -> Bool{
        //앱 델리게이트 객체 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
        //관리 객체 생성, 값 설정
        let object = NSEntityDescription.insertNewObject(forEntityName: "Board", into: context)
        object.setValue(title, forKey: "title")
        object.setValue(contents, forKey: "contents")
        object.setValue(Date(), forKey: "regdate")
        
        //영구 저장소에 커밋되고 나면 list 프로퍼티에 추가
        do{
            try context.save()
            self.list.insert(object, at: 0)
            return true
        }catch{
            context.rollback()
            return false
        }
    }
    
    
    func delete(object: NSManagedObject) -> Bool{
        //앱 델리게이트 객체 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
        //컨텍스트로부터 해당 객체 삭제
        context.delete(object)
        
        //영구 저장소에 커밋
        do{
            try context.save()
            return true
        }catch{
            context.rollback()
            return false
        }
    }
    
    func edit(object: NSManagedObject, title: String, contents: String) -> Bool{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        object.setValue(title, forKey: "title")
        object.setValue(contents, forKey: "contents")
        object.setValue(Date(), forKey: "regdate")
        
        do{
            try context.save()
            //수동 정렬
            self.list = self.fetch()
            return true
        }catch{
            context.rollback()
            return false
        }
    }
    
}
