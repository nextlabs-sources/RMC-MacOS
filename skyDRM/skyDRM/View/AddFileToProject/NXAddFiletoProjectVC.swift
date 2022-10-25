//
//  NXAddFiletoProjectVC.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/5/15.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXAddFiletoProjectVCDelegate: NSObjectProtocol {
    func addFileToProjectActionFinished(files: [NXNXLFile])
}

class NXAddFiletoProjectVC: NSViewController {

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    fileprivate var selectProjectView: NXAddFileSelectNewProjectView?
    fileprivate var reSelectTagsView: NXReSelectProjectTagsView?
    fileprivate var createFileView: NXAddFileCreateNewFileView?
    fileprivate var resultView: NXHomeProtectResultView?
    weak var delegate: NXAddFiletoProjectVCDelegate?
    var preFileModel: NXProjectFileModel?
    var rootModel: NXProjectRoot?
    var filePath: String?
    var tags: [String: [String]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    
    override func viewWillAppear() {
        self.view.window?.title = NXConstant.kTitle
        
        check()
    }
    
    private func check() {
        self.view.addSubview(NXLoadingView.sharedInstance)
        checkRight() { error in
            NXLoadingView.sharedInstance.removeFromSuperview()
            if let error = error {
                if let sdmlError = error as? SDMLError,
                    case SDMLError.commonFailed(reason: .networkUnreachable) = sdmlError {
                    NSAlert.showAlert(withMessage: "Lose Internet Connect".localized) { type in
                        self.closeWindow()
                    }
                    return
                }
                
                NSAlert.showAlert(withMessage: "You are not authorized to perform this operation.") { type in
                    self.closeWindow()
                }
                return
            }
            
            self.view.window?.delegate = self
            self.showSelectProjectView(syncFile: nil, projectModel: nil)
        }
    }
    
   fileprivate func showSelectProjectView(syncFile: NXSyncFile?, projectModel: NXProjectModel?) {
        removeAllViews()
        contentViewHeight.constant = 550
        if let window = self.view.window {
            window.styleMask.remove(.resizable)
            window.setContentSize(NSSize(width: 750, height: 550))
        }
        selectProjectView = NXCommonUtils.createViewFromXib(xibName: "NXAddFileSelectNewProjectView", identifier: "addFileSelectNewProjectView", frame: NSRect(x: 0, y: 0, width: (contentView?.frame.width)!, height: 550), superView: contentView) as? NXAddFileSelectNewProjectView
        selectProjectView?.delegate = self
        selectProjectView?.preFileModel = preFileModel
        selectProjectView?.syncFile     = syncFile
        selectProjectView?.projectModel = projectModel
        selectProjectView?.filePath     = filePath
        selectProjectView?.tags         = tags
        selectProjectView?.rootModel    = rootModel
    }
    
    fileprivate func showReselectProjectTagsView(syncFile: NXSyncFile?, projectModel: NXProjectModel?, destinationString: String?) {
        removeAllViews()
        if let window = self.view.window {
            window.styleMask.remove(.resizable)
            window.setContentSize(NSSize(width: 750, height: 600))
        }
        
        reSelectTagsView = NXCommonUtils.createViewFromXib(xibName: "NXReSelectProjectTagsView", identifier: "reSelectProjectTagsView", frame: NSRect(x: 0, y: 0, width: (contentView?.frame.width)!, height: 600), superView: contentView) as? NXReSelectProjectTagsView
        reSelectTagsView?.delegate        = self
        reSelectTagsView?.destinationStr  = destinationString
        reSelectTagsView?.preFileModel    = preFileModel
        reSelectTagsView?.filePath        = filePath
        reSelectTagsView?.tags            = tags
        if syncFile != nil, let fileModel = syncFile?.file as? NXProjectFileModel {
            
            var tagModel = NXProjectTagTemplateModel()
            if let prefileModel = preFileModel{
               tagModel = self.generateFileTagTemplate(jsontag: prefileModel.tags!, currentFileTagTemplate:fileModel.project!.tagTemplate!)
            }
            if let tags = tags {
                  tagModel = self.generateFileTagTemplate(jsontag: tags, currentFileTagTemplate:fileModel.project!.tagTemplate!)
            }
              reSelectTagsView?.tagModel    = self.inheirtTagesFromPreProjectTagTemplate(preTagTemplate: tagModel, currentTagTemplate: fileModel.project!.tagTemplate!)
           
        }else {
            var tagModel = NXProjectTagTemplateModel()
            if let prefileModel = preFileModel{
                tagModel = self.generateFileTagTemplate(jsontag: prefileModel.tags!, currentFileTagTemplate:projectModel!.tagTemplate!)
                
            }
            if let tags = tags{
                tagModel = self.generateFileTagTemplate(jsontag: tags, currentFileTagTemplate:projectModel!.tagTemplate!)
            }
            reSelectTagsView?.tagModel    = self.inheirtTagesFromPreProjectTagTemplate(preTagTemplate: tagModel, currentTagTemplate: projectModel!.tagTemplate!)
        }
        reSelectTagsView?.syncFile        = syncFile
        reSelectTagsView?.projectModel    = projectModel
    }
    
    fileprivate func removeAllViews() {
        selectProjectView?.removeFromSuperview()
        reSelectTagsView?.removeFromSuperview()
        createFileView?.removeFromSuperview()
        resultView?.removeFromSuperview()
    }
    
    fileprivate func generateFileTagTemplate(jsontag:[String: [String]],currentFileTagTemplate:NXProjectTagTemplateModel) ->NXProjectTagTemplateModel{
        let tageModel = NXProjectTagTemplateModel()
        var CategoryModelArray = [NXProjectTagCategoryModel]()
        tageModel.maxLabelNum = currentFileTagTemplate.maxLabelNum
        tageModel.maxCategoryNum = currentFileTagTemplate.maxCategoryNum
        for categoryName in jsontag.keys {
            let categoryModel = NXProjectTagCategoryModel()
            categoryModel.name = categoryName
            var labels = [NXProjectTagLabel]()
            let values = jsontag[categoryName]
            for label in values!{
                let labelInstance = NXProjectTagLabel()
                labelInstance.name = label
                labelInstance.isDefault = true
                labels.append(labelInstance)
            }
            categoryModel.labels = labels
            CategoryModelArray.append(categoryModel)
        }
        tageModel.categories = CategoryModelArray
        return tageModel
    }
    
    fileprivate func inheirtTagesFromPreProjectTagTemplate(preTagTemplate:NXProjectTagTemplateModel,currentTagTemplate:NXProjectTagTemplateModel) -> NXProjectTagTemplateModel{
        
        // tag inherit rules
        var realTag = NXProjectTagTemplateModel()
        var realCategory = [NXProjectTagCategoryModel]()
        
        var curCommonCategory = [NXProjectTagCategoryModel]()
        
        if currentTagTemplate.categories?.count == 0{
            realTag = preTagTemplate
        }
        
        realTag.categories = realCategory
        realTag.maxLabelNum = currentTagTemplate.maxLabelNum
        realTag.maxCategoryNum = currentTagTemplate.maxCategoryNum
        
        var preNameIDSet = Set<String>()
        var curNameIDSet = Set<String>()
    
        var justBelongToCurNameIDSet = Set<String>()
        var commonIDSet = Set<String>()
        
        let preTagTemplate_Enumerated_list = preTagTemplate.categories!.enumerated()
        for (_, projectTagCategoryModel) in  preTagTemplate_Enumerated_list {
            preNameIDSet.insert(projectTagCategoryModel.name!)
        }
        
        let currentTagTemplate_Enumerated_list1 = currentTagTemplate.categories!.enumerated()
        for (_, projectTagCategoryModel) in  currentTagTemplate_Enumerated_list1 {
             curNameIDSet.insert(projectTagCategoryModel.name!)
        }
        
        justBelongToCurNameIDSet = curNameIDSet.subtracting(preNameIDSet)
        commonIDSet = curNameIDSet.intersection(preNameIDSet)
        
        // add common tags
        if commonIDSet.count > 0 {
            let commonIDSet_enumerated_list = commonIDSet.enumerated()
            for (_, categoryName) in  commonIDSet_enumerated_list {
                for (_, projectTagCategoryModel) in  currentTagTemplate_Enumerated_list1 {
                    if categoryName == projectTagCategoryModel.name! {
                        //realCategory.append(projectTagCategoryModel)
                        curCommonCategory.append(projectTagCategoryModel)
                    }
                }
            }
            
            let preCommonCategoryModel_Enumerated_list = preTagTemplate.categories?.enumerated()
            let curCommonCategoryModel_Enumerated_list = curCommonCategory.enumerated()
            
            // set all label "default" property as "false" for curCommonCategory
            for (_,model) in curCommonCategoryModel_Enumerated_list{
                for label in model.labels!{
                   label.isDefault = false
               }
            }
            
            for (_,categoryModelPre) in preCommonCategoryModel_Enumerated_list!{
                for (_,categoryModelCur) in curCommonCategoryModel_Enumerated_list{
                    if categoryModelPre.name == categoryModelCur.name {
                        for labelPre in categoryModelPre.labels!{
                            for labelcure in categoryModelCur.labels!{
                                if labelPre.name == labelcure.name && labelPre.isDefault == true{
                                    labelcure.isDefault = true
                                }
                            }
                        }
                    }
                }
            }
            
            // for cycle end
            for category in curCommonCategory{
                realCategory.append(category)
            }
        }
        
        // add just belong to current tags
        if justBelongToCurNameIDSet.count > 0 {
            let justBelongToCurNameIDSet_Enumerated = justBelongToCurNameIDSet.enumerated()
            for (_, categoryName) in  justBelongToCurNameIDSet_Enumerated {
                for (_, projectTagCategoryModel) in  currentTagTemplate_Enumerated_list1 {
                    if categoryName == projectTagCategoryModel.name! {
                        for label in projectTagCategoryModel.labels! {
                            label.isDefault = false
                        }
                        realCategory.append(projectTagCategoryModel)
                    }
                }
            }
        }
        
        let cur_sort_Enumerated = currentTagTemplate.categories!.enumerated()
        let real_sort_Enumerated = realCategory.enumerated()
        var sortedrealCategory = [NXProjectTagCategoryModel]()
        
        for (index_cur,item_cur) in cur_sort_Enumerated
        {
            for (_ ,item_real) in real_sort_Enumerated
            {
                if item_cur.name == item_real.name{
                    sortedrealCategory.insert(item_real, at: index_cur)
                }
            }
        }
        realTag.categories = sortedrealCategory
        return realTag
    }
    
    private func checkRight(completion: @escaping (Error?) -> ()) {
        if let file = preFileModel {
            checkRight(file: file, completion: completion)
        } else {
            checkRight(path: filePath!, completion: completion)
        }
    }
    
    private func checkRight(file: NXProjectFileModel, completion: @escaping (Error?) -> ()) {
        let getContent: (NXProjectFileModel) -> (isTag: Bool, tags: [String: [String]]?, rights: [NXRightType]) = {  file in
            let isTag = file.isTagFile ?? false
            let tags = file.tags
            let rights = file.rights ?? []
            return (isTag: isTag, tags: tags, rights: rights)
        }
        
        if file.rights != nil,
            // FIXME: not get right should nil
            file.rights!.count != 0  {
            let content = getContent(file)
            checkRight(isTagFile: content.isTag, tags: content.tags, rights: content.rights, completion: completion)
            
        } else {
            NXClient.getObligationForViewInfo(file: NXSyncFile(file: file)) { (_, error) in
                if error != nil {
                    completion(error)
                    return
                }
                
                let content = getContent(file)
                self.checkRight(isTagFile: content.isTag, tags: content.tags, rights: content.rights, completion: completion)
            }
        }
    }
    
    private func checkRight(path: String, completion: @escaping (Error?) -> ()) {
        NXClient.getCurrentClient().getRight(path: path) { [weak self] (value, error) in
            guard let value = value else {
                completion(NSError())
                return
            }
            let isTag: Bool
            let tags: [String: [String]]?
            if let tagResult = value.tags {
                isTag = true
                tags = tagResult
            } else {
                isTag = false
                tags = nil
            }
            let rights = value.rights
            
            self?.tags = tags
            
            self?.checkRight(isTagFile: isTag, tags: tags, rights: rights.rights, completion: completion)
        }
    }
    
    private func checkRight(isTagFile: Bool, tags: [String: [String]]?, rights: [NXRightType], completion: @escaping (Error?) -> ()) {
        if isTagFile,
            rights.contains(.view) && rights.contains(.extract) {
            completion(nil)
            return
            
        } else {
            completion(NSError())
            return
        }
    }
    
    private func closeWindow() {
        self.view.window?.close()
        
    }
}

extension NXAddFiletoProjectVC: NXAddFileSelectNewProjectViewDelegate {
    func selectProjectFinished(syncFile: NXSyncFile?, projectModel: NXProjectModel?, destinationString: String?) {
        showReselectProjectTagsView(syncFile: syncFile, projectModel: projectModel, destinationString: destinationString)
    }
}

extension NXAddFiletoProjectVC: NXReSelectProjectTagsViewDeletage {
    func changeProjectAction(syncFile: NXSyncFile?, projectModel: NXProjectModel?) {
        showSelectProjectView(syncFile: syncFile, projectModel: projectModel)
    }
    
    func nextSelectTagsFinish(syncFile: NXSyncFile?, projectModel: NXProjectModel?, tags: [String: [String]], destinationStr: String) {
        removeAllViews()
        if let window = self.view.window {
            window.styleMask.remove(.resizable)
            window.setContentSize(NSSize(width: 750, height: 550))
        }
        createFileView = NXCommonUtils.createViewFromXib(xibName: "NXAddFileCreateNewFileView", identifier: "NXAddFileCreateNewFileView", frame: nil, superView: contentView) as? NXAddFileCreateNewFileView
        createFileView?.delegate       = self
        createFileView?.destinationStr = destinationStr
        createFileView?.tags           = tags
        createFileView?.filePath       = filePath
        createFileView?.preFileModel   = preFileModel
        createFileView?.syncFile       = syncFile
        createFileView?.projectModel   = projectModel
    }
}

extension NXAddFiletoProjectVC: NXAddFileCreateNewFileViewDelegate {
    func addFileFinished(file: NXNXLFile, tags:[String: [String]], right: NXRightObligation?, destinationStr: String){
        removeAllViews()
        resultView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectResultView", identifier: "homeProtectResultView", frame: nil, superView: contentView) as? NXHomeProtectResultView
        resultView?.delegate = self
        resultView?.selectedFile = [file]
        resultView?.destPathStr = destinationStr
        resultView?.tags = tags
        resultView?.right = right
        resultView?.heightForView.constant = 90
    }
    
    func backAction(syncFile: NXSyncFile?, projectModel: NXProjectModel?, destinationString: String?){
        showReselectProjectTagsView(syncFile: syncFile, projectModel: projectModel, destinationString: destinationString)
    }
}

extension NXAddFiletoProjectVC: NXHomeProtectResultViewDelegate {
    
    func closeProtectResult(files: [NXNXLFile]) {
        self.delegate?.addFileToProjectActionFinished(files: files)
        self.presentingViewController?.dismiss(self)
    }
}

extension NXAddFiletoProjectVC: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let files = resultView?.selectedFile {
            self.delegate?.addFileToProjectActionFinished(files: files)
            self.presentingViewController?.dismiss(self)
        }
    }
}
