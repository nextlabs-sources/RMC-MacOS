//
//  NXCommonUtils+SDML.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 8/20/19.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import SDML

extension NXCommonUtils {
    static func transform(from: SDMLBaseFile, to: NXFileBase) {
        to.name = from.getName()
        to.lastModifiedDate = from.getModifiedTime() as NSDate
        to.fullServicePath = from.getPathID()
        to.size = Int64(from.getSize())
        to.localPath = from.getLocalPath()
        if to.localPath.count > 6 {
            to.localFile = true
            
        }
        to.sdmlBaseFile = from
    }
    
    static func transform(from: SDMLNXLFile, to: NXNXLFile) {
        NXCommonUtils.transform(from: from as SDMLBaseFile, to: to)
        to.isOffline      = from.getIsLocation()
        to.setNXLID(nxlId: from.getDUID())
        to.recipients     = from.getRecipients()
        to.originFilePath = from.getSourcePath()
        to.isTagFile      = from.isTagFile()
        to.tags           = from.getTag()
        to.isOwner        = from.getIsOwner()
        
        if let obRights = from.getRightObligation() {
            var rights = [NXRightType]()
            NXCommonUtils.transform(from: obRights.rights, to: &rights)
            to.rights = rights
            
            var watermark: NXFileWatermark?
            NXCommonUtils.transform(from: obRights.watermark, to: &watermark)
            to.watermark = watermark
            
            var expiry: NXFileExpiry?
            NXCommonUtils.transform(from: obRights.expiry, to: &expiry)
            to.expiry = expiry
            
        }
    }
    
    
    static func transform(from: SDMLMyVaultFile, to: NXMyVaultFile) {
        NXCommonUtils.transform(from: from as SDMLNXLFile, to: to)
        to.isLocation = from.getIsLocation()
        to.pathId     = from.getPathID()
    }
    
    static func transform(from: SDMLShareWithMeFile, to: NXShareWithMeFile) {
        NXCommonUtils.transform(from: from as SDMLNXLFile, to: to)
        to.fileType = from.getFileType()
        to.shareBy = from.getSharedBy()
        to.isLocation = from.getIsLocation()
        to.shareDate = from.getSharedDate()
        to.shareLink = from.getSharedLink()
        to.transactionCode = from.getTransactionCode()
        to.transactionId = from.getTransactionId()
    }
    
    static func transform(from: SDMLProject, to: NXProjectModel) {
        to.name               = from.getName()
        to.parentTenantName   = from.getParentTenantName()
        to.parentTenantId     = from.getParentTenantId()
        to.totalFiles         = from.getFileManager().getTotalFiles()
        to.totalMembers       = from.getTotalMembers()
        to.displayName        = from.getDisplayName()
        to.projectDescription = from.getDescription()
        to.id                 = from.getId()
        to.tokenGroupName     = from.getTokenGroupName()
        to.ownedByMe          = from.isOwnedByMe()
        to.creationTime       = from.getCreationTime()
        to.trialEndTime       = from.getTrialEndTime()
        to.sdmlProject        = from
        
        let tagTemplateModel  = NXProjectTagTemplateModel()
        transform(from: from.getProjectTags()!, to: tagTemplateModel)
        to.tagTemplate        = tagTemplateModel
        
        let user              = NXProjectUserInfo()
        user.creationTime     = from.getOwner().getCreationTime()
        user.displayName      = from.getOwner().getDisplayName()
        user.email            = from.getOwner().getEmail()
        user.userId           = from.getOwner().getUserId()
        to.owner              = user
    }
    
    static func transform(from: SDMLProject, to: NXProjectModel, isUpdate: Bool = false) {
        transform(from: from, to: to)
        
        var members = [NXProjectMemberModel]()
        for sdmlMember in from.getMembers() {
            let memberModel = NXProjectMemberModel()
            memberModel.projectId    = from.getId()
            memberModel.email        = sdmlMember.getEmail()
            memberModel.displayName  = sdmlMember.getDisplayName()
            memberModel.creationTime = sdmlMember.getCreationTime()
            memberModel.userId       = sdmlMember.getUserId()
            members.append(memberModel)
        }
        to.memabers                  = members
        var rootFiles = [NXSyncFile]()
        var folders = [NXSyncFile]()
        for projectFile in from.getFileManager().getRootFiles() {
            let fileModel = NXProjectFileModel()
            NXCommonUtils.transform(from: projectFile, to: fileModel, parentFile: nil, project: to, isUpdate: isUpdate)
            let syncFile = NXSyncFile(file: fileModel)
            let status = NXSyncFileStatus()
            status.status = fileModel.isOffline==true ?.completed :.pending
            status.type = .download
            syncFile.syncStatus = status
            rootFiles.append(syncFile)
            if fileModel.isFolder == true{
                folders.append(syncFile)
            }
        }
        // Sort folder: lowercase character order
        to.folders   = folders.sorted() {$0.file.name.lowercased() < $1.file.name.lowercased()}
        to.rootFiles = rootFiles
        
    }
    
    static func transform(from: SDMLProjectTagTemplate, to: NXProjectTagTemplateModel) {
        to.maxLabelNum = from.getMaxLabelNum()
        to.maxCategoryNum = from.getMaxCategoryNum()
        var categories = [NXProjectTagCategoryModel]()
        for sdmlCategory in from.getCategories() {
            let categoryModel = NXProjectTagCategoryModel()
            categoryModel.name = sdmlCategory.getName()
            categoryModel.mandatory = sdmlCategory.getMmandatory()
            categoryModel.multiSelect = sdmlCategory.getMultiSelect()
            var labels = [NXProjectTagLabel]()
            for sdmlLabel in sdmlCategory.getLabels() {
                let labelModel       = NXProjectTagLabel()
                labelModel.name      = sdmlLabel.getName()
                labelModel.isDefault = sdmlLabel.getIsDefault()
                labels.append(labelModel)
            }
            categoryModel.labels = labels
            categories.append(categoryModel)
        }
        to.categories = categories
    }
    
    static func transform(from: SDMLOutBoxFile, to: NXLocalProjectFileModel) {
        NXCommonUtils.transform(from: from as SDMLNXLFile, to: to)
        to.projectId    = from.getProjectId()
        to.parentFileId = from.getParentFileId()
        to.projectName  = from.getProjectName()
    }
    
    static func transform(from: SDMLOutBoxFile, to: NXWorkspaceLocalFile) {
        NXCommonUtils.transform(from: from as SDMLNXLFile, to: to)
        let parentID: String?
        if from.getParentPathId() == "/" {
            parentID = nil
        } else {
            parentID = from.getParentPathId()
        }
        to.parentID = parentID
    }
    
    static func transform(from: SDMLProjectFile, to: NXProjectFileModel , parentFile: NXProjectFileModel?, project: NXProjectModel, isUpdate: Bool = false) {
        NXCommonUtils.transform(from: from , to: to)
        to.project = project
        
        if from.getParentFile() != nil {
            to.parentFileID = from.getParentFile()?.getFileId()
        }
        
        if from.getIsFolder() {
            var subFolders = [NXSyncFile]()
            var subFiles = [NXSyncFile]()
            if from.getSubFiles().count != 0 {
                let subParentFile = NXProjectFileModel()
                NXCommonUtils.transform(from: from , to: subParentFile)
                subParentFile.project = project
                for subFile in  from.getSubFiles() {
                    let file = NXProjectFileModel()
                    transform(from: subFile, to: file, parentFile: subParentFile, project: project)
                    
                    let syncFile = NXSyncFile(file: file)
                    let status = NXSyncFileStatus()
                    status.status = file.isOffline==true ?.completed :.pending
                    status.type = .download
                    syncFile.syncStatus = status
                    subFiles.append(syncFile)
                    
                    if file.isFolder == true {
                        subFolders.append(syncFile)
                    }
                }
            }
            // Sort folder: lowercase character order
            to.subFolders = subFolders.sorted() {$0.file.name.lowercased() < $1.file.name.lowercased()}
            to.subfiles   = subFiles
        }
    }
    
    static func transform(from: SDMLProjectFile, to: NXProjectFileModel) {
        NXCommonUtils.transform(from: from as SDMLNXLFile, to: to)
        to.fileType         = from.getFileType()
        to.isFolder         = from.getIsFolder()
        to.isNXL            = true
        to.fileId           = from.getFileId()
        to.pathDisplay      = from.getPathDisplay()
    }
    
    static func transform(from: [NXRightType], to: inout [SDMLFileRight]) {
        var result = [SDMLFileRight]()
        result.reserveCapacity(from.count)
        for value in from {
            let right: SDMLFileRight?
            switch value {
            case .view:
                right = SDMLFileRight.view
            case .print:
                right = SDMLFileRight.print
            case .share:
                right = SDMLFileRight.share
            case .saveAs:
                right = SDMLFileRight.saveas
            case .edit:
                right = SDMLFileRight.edit
            case .extract:
                right = SDMLFileRight.decrypt
            default:
                right = nil
            }
            
            if let right = right {
                result.append(right)
            }
            
            result.sort {
                return $0.rawValue < $1.rawValue
            }
        }
        
        to = result
    }
    
    static func transform(from: [SDMLFileRight], to: inout [NXRightType]) {
        var result = [NXRightType]()
        result.reserveCapacity(from.count)
        
        for value in from {
            let right: NXRightType?
            switch value {
            case .view:
                right = NXRightType.view
            case .print:
                right = NXRightType.print
            case .share:
                right = NXRightType.share
            case .saveas:
                right = NXRightType.saveAs
            case .edit:
                right = NXRightType.edit
            case .decrypt:
                right = NXRightType.extract
            default:
                right = nil
            }
            
            if let right = right {
                result.append(right)
            }
            result.sort {
                return $0.rawValue < $1.rawValue
            }
        }
        
        to = result
    }
    
    static func transform(from: NXFileWatermark?, to: inout SDMLWatermark?) {
        if let from = from {
            to = SDMLWatermark(text: from.text)
        }
    }
    
    static func transform(from: SDMLWatermark?, to : inout NXFileWatermark?) {
        if let from = from {
            to = NXFileWatermark(text: from.getText())
        }
    }
    
    static func transform(from: NXFileExpiry?, to: inout SDMLExpiry?) {
        guard let from = from else {
            return
        }
        
        var startInt: UInt64 = 0
        if let start = from.start {
            startInt = UInt64(start.timeIntervalSince1970 * 1000)
        }
        
        var endInt: UInt64 = 0
        if let end = from.end {
            endInt = UInt64(end.timeIntervalSince1970 * 1000)
        }
        
        switch from.type {
        case .neverExpire:
            to = SDMLExpiry(type: .neverExpire, start: 0, end: 0)
        case .absoluteExpire:
            to = SDMLExpiry(type: .absoluteExpire, start: 0, end: endInt)
        case .relativeExpire:
            to = SDMLExpiry(type: .relativeExpire, start: 0, end: endInt)
        case .rangeExpire:
            to = SDMLExpiry(type: .rangeExpire, start: startInt, end: endInt)
        }
    }
    
    static func transform(from: SDMLPreferenceExpiry) -> NXFileExpiry {
        let to: NXFileExpiry
        switch from {
        case .never:
            to = NXFileExpiry(type: .neverExpire, start: nil, end: nil)
        case .relative(let year, let month, let week, let day):
            var components = DateComponents()
            components.year = year
            components.month = month
            components.weekday = week
            components.day = day
            
            let now = Date()
            let endDate = Calendar.current.date(byAdding: components, to: now)
            to = NXFileExpiry(type: .relativeExpire, start: nil, end: endDate)
        case .absolute(let end):
            let endDate = Date(timeIntervalSince1970: TimeInterval(end)/1000)
            to = NXFileExpiry(type: .absoluteExpire, start: nil, end: endDate)
        case .range(let start, let end):
            let startDate = Date(timeIntervalSince1970: TimeInterval(start)/1000)
            let endDate = Date(timeIntervalSince1970: TimeInterval(end)/1000)
            to = NXFileExpiry(type: .rangeExpire, start: startDate, end: endDate)
        }
        
        return to
    }
    
    static func transform(from: SDMLExpiry?, to: inout NXFileExpiry?) {
        guard let from = from else {
            return
        }
        
        switch from.type {
        case .neverExpire:
            to = NXFileExpiry(type: .neverExpire, start: nil, end: nil)
        case .absoluteExpire:
            let end = Date(timeIntervalSince1970: TimeInterval(from.end)/1000)
            to = NXFileExpiry(type: .absoluteExpire, start: nil, end: end)
        case .relativeExpire:
            let end = Date(timeIntervalSince1970: TimeInterval(from.end)/1000)
            to = NXFileExpiry(type: .relativeExpire, start: nil, end: end)
        case .rangeExpire:
            let start = Date(timeIntervalSince1970: TimeInterval(from.start)/1000)
            let end = Date(timeIntervalSince1970: TimeInterval(from.end)/1000)
            to = NXFileExpiry(type: .rangeExpire, start: start, end: end)
            
        }
    }
    
    static func transform(from: NXRightObligation, to: inout SDMLRightObligation?) {
        let rights = from.rights.sorted { (left, right) -> Bool in
            return left.rawValue < right.rawValue
        }
        
        var sdmlRight = [SDMLFileRight]()
        NXCommonUtils.transform(from: rights, to: &sdmlRight)
        var sdmlWatermark: SDMLWatermark?
        if let watermark = from.watermark {
            NXCommonUtils.transform(from: watermark, to: &sdmlWatermark)
        }
        var sdmlExpiry: SDMLExpiry?
        if let expiry = from.expiry {
            NXCommonUtils.transform(from: expiry, to: &sdmlExpiry)
        }
        
        to = SDMLRightObligation(rights: sdmlRight, watermark: sdmlWatermark, expiry: sdmlExpiry)
    }
    static func transform(from: SDMLRightObligation, to: NXRightObligation) {
        var rights = [NXRightType]()
        NXCommonUtils.transform(from: from.rights, to: &rights)
        to.rights = rights
        
        var watermark: NXFileWatermark?
        NXCommonUtils.transform(from: from.watermark, to: &watermark)
        to.watermark = watermark
        
        var expiry: NXFileExpiry?
        NXCommonUtils.transform(from: from.expiry, to: &expiry)
        to.expiry = expiry
    }
    
    static func transform(from: SDMLUserInfo, to: NXProjectUserInfo) {
        to.userId = from.getUserId()
        to.displayName = from.getDisplayName()
        to.email = from.getEmail()
        to.creationTime = from.getCreationTime()
    }
}
