import MEGARepo

extension CameraUploadRecordManager: CameraUploadRecordStore {
    public func fetchAssetUploads(
        startingFrom cursor: QueuedCameraUploadCursorDTO?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusDTO],
        mediaTypes: [PHAssetMediaType]
    ) async throws -> [AssetUploadRecordDTO] {
        let context = backgroundContext
        return try await context.perform {
            let request: NSFetchRequest<MOAssetUploadRecord> = MOAssetUploadRecord.fetchRequest()
            request.returnsObjectsAsFaults = false
            
            var predicates = [
                self.predicateByFilterAssetUploadRecordError()
            ]
            if statuses.isNotEmpty {
                predicates.append(NSPredicate(format: "status IN %@", statuses.map { $0.toCameraAssetUploadStatus().rawValue }))
            }
            if mediaTypes.isNotEmpty {
                let mediaTypePredicate = NSPredicate(format: "mediaType IN %@", mediaTypes.map(\.rawValue))
                predicates.append(mediaTypePredicate)
            }
            if let cursorPredicate = try self.makeCursorPredicate(cursor: cursor, isForward: isForward, in: context) {
                predicates.append(cursorPredicate)
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: isForward),
                NSSortDescriptor(key: "localIdentifier", ascending: isForward)
            ]
            
            request.relationshipKeyPathsForPrefetching = ["errorPerLaunch", "errorPerLogin"]
            if let limit {
                request.fetchLimit = limit
            }
            
            let records = try context.fetch(request)
            
            return records
                .compactMap { $0.toAssetUploadRecordDTO() }
        }
    }
    
    public func fetchAssetUploadFileNames(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<AssetUploadFileNameRecordDTO> {
        let context = backgroundContext
        return try await context.perform {
            let request: NSFetchRequest<MOAssetUploadRecord> = MOAssetUploadRecord.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "localIdentifier IN %@", Array(identifiers))
            request.relationshipKeyPathsForPrefetching = ["fileNameRecord"]
            
            let records = try context.fetch(request)
            
            return Set(records.compactMap {
                guard let localIdentifier = $0.localIdentifier else { return nil }
                return $0.fileNameRecord?.toAssetUploadFileNameRecordDTO(localIdentifier: localIdentifier)
            })
        }
    }
    
    private func makeCursorPredicate(cursor: QueuedCameraUploadCursorDTO?, isForward: Bool, in context: NSManagedObjectContext) throws -> NSPredicate? {
        guard let cursor else { return nil }
        
        let comparison = isForward ? ">" : "<"
        
        let datePredicate = NSPredicate(format: "creationDate \(comparison) %@", cursor.creationDate as NSDate)
        let sameDate = NSPredicate(format: "creationDate == %@", cursor.creationDate as NSDate)
        let identifierPredicate = NSPredicate(format: "localIdentifier \(comparison) %@", cursor.localIdentifier)
        let sameDateAndIdentifier = NSCompoundPredicate(andPredicateWithSubpredicates: [sameDate, identifierPredicate])
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [datePredicate, sameDateAndIdentifier])
    }
}
