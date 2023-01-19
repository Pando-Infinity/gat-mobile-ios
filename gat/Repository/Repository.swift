//
//  Repository.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

enum RepositoryError: Error {
    case save(String)
    case delete(String)
    
    var localizedDescription: String {
        switch self {
        case .save(let message):
            return "Save error: \(message)"
        case .delete(let message):
            return "Delete error: \(message)"
        }
    }
}

class Repository<T: ObjectConvertable, V: Object & DomainConvertable> where T.Object == V, V.Domain == T {
    
    fileprivate var realm: Realm?
    
    static var shared: Repository<T, V> {
        return Repository()
    }
    
    fileprivate init() {
        do {
            self.realm = try Realm()
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func getAll(predicateFormat: String? = nil, args: [Any]? = nil, sortBy: String? = nil, ascending: Bool? = nil, start: Int? = nil, end: Int? = nil) -> Observable<[T]> {
        var result = self.realm?.objects(V.self)
        if let format = predicateFormat {
            result = result?.filter(NSPredicate(format: format, argumentArray: args))
        }
        if let sort = sortBy, let ascending = ascending {
            result = result?.sorted(byKeyPath: sort, ascending: ascending)
        }
        var list = [T]()
        if let start = start, let end = end, let r = result, start > 0 && end > 0  {
            list = (start...end).compactMap { $0 < r.count ? r[$0] : nil }.map { $0.asDomain() }
        } else {
            list = result?.map { $0.asDomain() } ?? []
        }
        
        return Observable<[T]>.just(list)
    }
    
    func getFirst(predicateFormat: String? = nil, args: [Any]? = nil) -> Observable<T> {
        var result = self.realm?.objects(V.self)
        if let format = predicateFormat {
            result = result?.filter(NSPredicate(format: format, argumentArray: args))
        }
        if let object = result?.first {
            return Observable<T>.just(object.asDomain())
        } else {
            return Observable.empty()
        }
    }
    
    func get(predicateFormat: String? = nil, args: [Any]? = nil) -> T? {
        var result = self.realm?.objects(V.self)
        if let format = predicateFormat {
            result = result?.filter(NSPredicate(format: format, argumentArray: args))
        }
        return result?.first?.asDomain()
    }
    
    func getLast(predicateFormat: String? = nil, args: [Any]? = nil) -> Observable<T> {
        var result = self.realm?.objects(V.self)
        if let format = predicateFormat {
            result = result?.filter(NSPredicate(format: format, argumentArray: args))
        }
        if let object = result?.last {
            return Observable<T>.just(object.asDomain())
        } else {
            return Observable.empty()
        }
    }
    
    func save(object: T) -> Observable<()> {
        do {
            try self.realm?.write { [weak self] in
                self?.realm?.add(object.asObject(), update: .all)
            }
            
            return Observable<()>.just(())
        } catch {
            return Observable<()>.error(RepositoryError.save(error.localizedDescription))
        }
    }
    
    func save(objects: [T]) -> Observable<()> {
        do {
            try self.realm?.write { [weak self] in
                self?.realm?.add(objects.map { $0.asObject() }, update: .all)
            }
            return Observable<()>.just(())
        } catch {
            return Observable<()>.error(RepositoryError.save(error.localizedDescription))
        }
        
    }
    
    func deleteAll() -> Observable<()> {
        return Observable<Results<V>>
            .from(optional: self.realm?.objects(V.self))
            .flatMapLatest({ [weak self] (list) -> Observable<()> in
                do {
                    try self?.realm?.write { [weak self] in
                        self?.realm?.delete(list)
                    }
                    return Observable<()>.just(())
                } catch {
                    return Observable<()>.error(RepositoryError.delete(error.localizedDescription))
                }
                
            })
    }
    
    func removeAll(predicate: NSPredicate? = nil, sorts: [NSSortDescriptor] = [], range: ClosedRange<Int>? = nil) -> Observable<()> {
        var result = self.realm?.objects(V.self)
        if let predicate = predicate {
            result = result?.filter(predicate)
        }
        if !sorts.isEmpty {
            sorts.filter { $0.key != nil }.forEach { (sort) in
                result = result?.sorted(byKeyPath: sort.key!, ascending: sort.ascending)
            }
        }
        guard let r = result else { return .empty() }
        if let range = range, range.max()! < r.count && range.min()! >= 0 {
            do {
                try self.realm?.write { [weak self] in
                    self?.realm?.delete(range.map { r[$0] })
                }
                return Observable<()>.just(())
            } catch {
                return Observable<()>.error(RepositoryError.delete(error.localizedDescription))
            }
        } else {
            do {
                try self.realm?.write { [weak self] in
                    self?.realm?.delete(r)
                }
                return Observable<()>.just(())
            } catch {
                return Observable<()>.error(RepositoryError.delete(error.localizedDescription))
            }
        }
    }
    
}

extension Repository where V: PrimaryValueProtocol {
    func delete(object: T) -> Observable<()> {
        return Observable<T>
            .just(object)
            .flatMapLatest { [weak self] in Observable<V?>.just(self?.realm?.object(ofType: V.self, forPrimaryKey: $0.asObject().primaryValue())) }
            .flatMapLatest({ [weak self] (object) -> Observable<()> in
                if let o = object {
                    do {
                        try self?.realm?.write { [weak self] in
                            self?.realm?.delete(o)
                        }
                    } catch {
                        return Observable<()>.error(RepositoryError.delete(error.localizedDescription))
                    }
                }
                return Observable<()>.just(())
            })
    }
    
    func delete(objects: [T]) -> Observable<()> {
        return Observable<T>
            .from(objects)
            .flatMapLatest { [weak self] in Observable<V?>.just(self?.realm?.object(ofType: V.self, forPrimaryKey: $0.asObject().primaryValue())) }
            .flatMapLatest({ [weak self] (object) -> Observable<()> in
                if let o = object {
                    do {
                        try self?.realm?.write { [weak self] in
                            self?.realm?.delete(o)
                        }
                    } catch {
                        return Observable<()>.error(RepositoryError.delete(error.localizedDescription))
                    }
                }
                return Observable<()>.just(())
            })
    }
    
    
}
