import MEGARepo

extension CameraUploadRecordManager: CameraUploadRecordStore {
    public func fetchAssetUploads(
        startingFrom localIdentifier: String?,
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
            if let cursorPredicate = try self.makeCursorPredicate(localIdentifier: localIdentifier, isForward: isForward, in: context) {
                predicates.append(cursorPredicate)
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: !isForward),
                NSSortDescriptor(key: "localIdentifier", ascending: !isForward)
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
    
    private func makeCursorPredicate(localIdentifier: String?, isForward: Bool, in context: NSManagedObjectContext) throws -> NSPredicate? {
        guard let localIdentifier,
              let record = try uploadRecord(localIdentifier: localIdentifier, in: context),
              let creationDate = record.creationDate,
              let localId = record.localIdentifier else { return nil }
        
        let comparison = isForward ? "<" : ">"
        let datePredicate = NSPredicate(format: "creationDate \(comparison) %@", creationDate as NSDate)
        let sameDatePredicate = NSPredicate(format: "creationDate == %@ AND localIdentifier \(comparison) %@", creationDate as NSDate, localId)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [datePredicate, sameDatePredicate])
    }
    
    private func uploadRecord(localIdentifier: String, in context: NSManagedObjectContext) throws -> MOAssetUploadRecord? {
        let request: NSFetchRequest<MOAssetUploadRecord> = MOAssetUploadRecord.fetchRequest()
        request.predicate = NSPredicate(format: "localIdentifier == %@", localIdentifier)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
