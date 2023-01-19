//
//  GuidelineService.swift
//  gat
//
//  Created by jujien on 6/23/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

struct GuidelineService {
    static let shared = GuidelineService()
    
    fileprivate let disposeBag = DisposeBag()
    
    var flows: Observable<[FlowGuideline]> {
        Repository<FlowGuideline, FlowGuidelineObject>.shared.getAll()
    }
    
    fileprivate init() {
        if self.gotoUserPage == nil {
            let gotoUserPage = FlowGuideline(id: 1, name: "Goto User Page", steps: [
                .init(id: 1, completed: false, name: "Goto UserPage")
            ])
            Repository<FlowGuideline, FlowGuidelineObject>.shared.save(object: gotoUserPage).subscribe().disposed(by: self.disposeBag)
        }
        if self.addBook == nil {
            let addBook = FlowGuideline(id: 2, name: "Add Book", steps: [
                .init(id: 2, completed: false, name: "Tap Add Button"),
                .init(id: 3, completed: false, name: "Search Book"),
                .init(id: 4, completed: false, name: "Result Book")
            ])
            Repository<FlowGuideline, FlowGuidelineObject>.shared.save(object: addBook).subscribe().disposed(by: self.disposeBag)
        }
        if self.borrowBook == nil {
            let borrowBook = FlowGuideline(id: 3, name: "Borrow Book", steps: [
                .init(id: 5, completed: false, name: "Borrow Book")
            ])
            Repository<FlowGuideline, FlowGuidelineObject>.shared.save(object: borrowBook).subscribe().disposed(by: self.disposeBag)
        }
    }
    
    func cancel() {
        self.flows.map { (guides) -> [FlowGuideline] in
            return guides.map { (guide) -> FlowGuideline in
                var guide = guide
                guide.steps = guide.steps.map({ (step) -> StepGuideline in
                    var step = step
                    step.completed = true
                    return step
                })
                return guide
            }
        }
        .flatMap { Repository<FlowGuideline, FlowGuidelineObject>.shared.save(objects: $0) }
        .subscribe()
        .disposed(by: self.disposeBag)
    }
    
    func complete(step: StepGuideline) {
        var step = step
        step.completed = true
        Repository<StepGuideline, StepGuidelineObject>.shared.save(object: step).subscribe().disposed(by: self.disposeBag)
    }
    
    func complete(flow: FlowGuideline) {
        var flow = flow
        flow.steps = flow.steps.map({ (step) -> StepGuideline in
            var step = step
            step.completed = true 
            return step
        })
        Repository<FlowGuideline, FlowGuidelineObject>.shared.save(object: flow).subscribe().disposed(by: self.disposeBag)
    }
}

extension GuidelineService {
    var gotoUserPage: FlowGuideline? {
        return Repository<FlowGuideline, FlowGuidelineObject>.shared.get(predicateFormat: "id == %d", args: [1])
    }
    
    var addBook: FlowGuideline? {
        return Repository<FlowGuideline, FlowGuidelineObject>.shared.get(predicateFormat: "id == %d", args: [2])
    }
    
    var borrowBook: FlowGuideline? {
        return Repository<FlowGuideline, FlowGuidelineObject>.shared.get(predicateFormat: "id == %d", args: [3])
    }
}

struct FlowGuideline {
    var id: Int
    var name: String
    var steps: [StepGuideline]
    
    var complete: Bool { return self.steps.reduce(true, { $0 && $1.completed }) }
}

extension FlowGuideline: ObjectConvertable {
    func asObject() -> FlowGuidelineObject {
        let object = FlowGuidelineObject()
        object.id = self.id
        object.name = self.name
        self.steps.map { $0.asObject() }.forEach { (step) in
            object.steps.append(step)
        }
        return  object
    }
}

class FlowGuidelineObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    var steps: List<StepGuidelineObject> = .init()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension FlowGuidelineObject: DomainConvertable {
    func asDomain() -> FlowGuideline {
        return .init(id: self.id, name: self.name, steps: self.steps.map { $0.asDomain() })
    }
}

struct StepGuideline {
    var id: Int
    var completed: Bool
    var name: String
}

extension StepGuideline: ObjectConvertable {
    func asObject() -> StepGuidelineObject {
        let object = StepGuidelineObject()
        object.id = self.id
        object.name = name
        object.completed = completed
        return object
    }
}

class StepGuidelineObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var completed = false
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension StepGuidelineObject: DomainConvertable {
    func asDomain() -> StepGuideline {
        return StepGuideline(id: self.id, completed: self.completed, name: self.name)
    }
}
