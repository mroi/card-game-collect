//
//  CardGame+CoreDataProperties.swift
//  Quartets
//
//  Created by Paula on 01.11.20.
//
//

import Foundation
import CoreData


extension CardGame {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardGame> {
        return NSFetchRequest<CardGame>(entityName: "CardGame")
    }

    @NSManaged public var title: String?
    @NSManaged public var publisher: String?
    @NSManaged public var type: CardGameType
    @NSManaged public var publishDate: Date?
    @NSManaged public var isYearPrecise: Bool
    @NSManaged public var stateOfPreservation: StateOfPreservation
    @NSManaged public var isDuplicate: Bool
    @NSManaged public var hasBox: Bool
    @NSManaged public var totalCardsCount: Int16
    @NSManaged public var missingCardsCount: Int16
    @NSManaged public var missingCardsText: String?
    @NSManaged public var comment: String?
    @NSManaged public var oderID: String?
    @NSManaged public var lastUpdateDate: Date?

}

extension CardGame : Identifiable {

}
