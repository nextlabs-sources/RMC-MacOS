//
//  NXProjectServiceTests.swift
//  skyDRM
//
//  Created by pchen on 20/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import XCTest

class NXProjectServiceTests: XCTestCase {

    var projectService: NXProjectService!
    
    struct Constants {
        static let timeout: TimeInterval = 20.0
    }
    
    var expection: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let googleAccount = ("28", "32F27FA66EF10B47355105C37D1C1F05")
        let skyDrmAccount = ("40", "279EC9C14EF46C6E63C3B76E0BA1A1E7")
        let account: (String, String) = googleAccount
        projectService = NXProjectService(withUserID: account.0, ticket: account.1)
        projectService.delegate = self
    }
    
    func testlistProject() {
        let ownedByUser = NXListProjectType.allProject
        projectService.listProject(ownedByUser: ownedByUser)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }
    
    func testGetProjectMetadata() {
        
        let project = NXProject()
        project.projectId = "18"
        projectService.getProjectMetadata(project: project)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testCreateProject() {
        let project = NXProject()
        project.name = "project1"
        project.projectDescription = "second project"
        projectService.createProject(project: project, invitedEmails: nil)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }
//
    func testUploadFile() {
        
        ///
        /// Parameter include:
        ///      projectId: Int
        ///      fileName: String
        ///      rightsJSON: Array
        ///      tags: [String: Any]
        ///      destFilePathId: String
        ///      destFilePathDisplay: String
        ///
        let file = NXProjectFile()
        file.fileName = "1.txt"
        file.filePath = "/Users/pchen/Desktop/1.txt"
        let folder = NXProjectFolder()
        folder.projectId = "25"
        folder.path = "/"
        let uploadProperty = NXProjectUploadFileProperty(rights: [NXProjectFileRightType.view], tags: ["Confidentiality" : ["SECRET", "TOP SECRET"]])
        
        projectService.uploadFile(fromFile: file, toFolder: folder, property: uploadProperty)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testCancelUploadFile() {
        
        let file = NXProjectFile()
        file.fileName = "1.txt"
        file.filePath = "/Users/pchen/Desktop/1.txt"
        let folder = NXProjectFolder()
        folder.projectId = "18"
        folder.path = "/"
        let uploadProperty = NXProjectUploadFileProperty(rights: [NXProjectFileRightType.view], tags: ["Confidentiality" : ["SECRET", "TOP SECRET"]])
        projectService.uploadFile(fromFile: file, toFolder: folder, property: uploadProperty)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            if self.projectService.cancelUploadFile(fromFile: file, toFolder: folder) {
                self.expection?.fulfill()
            } else {
                assertionFailure()
            }
        }
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testListFile() {
        ///
        /// Parameter include:
        ///      projectId: Int
        ///      page: Int
        ///      size: Int
        ///      orderBy: Array
        ///      parentPath: String
        ///
        let project = NXProject()
        project.projectId = "18"
        let filter = NXProjectFileFilter(page: "1", size: "10", orderBy: [NXProjectFileSortType.fileName(isAscend: true)], parentPath: "/")
        projectService.listFile(project: project, filter: filter)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testCreateFolder() {
        
        let folder = NXProjectFolder()
        folder.name = "new"
        
        let parentFolder = NXProjectFolder()
        parentFolder.projectId = "25"
        parentFolder.path = "/"
        
        let autorename = false
        projectService.createFolder(folder: folder, parentFolder: parentFolder, autorename: autorename)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testDeleteFile() {
        let folder = NXProjectFolder()
        folder.projectId = "25"
        folder.path = "/new/"
        projectService.deleteFile(file: folder)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testGetFileMetadata() {
        let file = NXProjectFile()
        file.projectId = "25"
        file.filePath = "/1-2017-02-21-08-16-02.txt.nxl"
        projectService.getFileMetadata(file: file)
    }

    func testSearch() {
        let project = NXProject()
        project.projectId = "25"
        
        let query = "1"
        projectService.searchFile(project: project, query: query)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }
//
    func testDownlodFile() {
        ///
        /// Parameter include:
        ///      projectId: Int
        ///      start: Int64
        ///      length: Int64
        ///      path: String
        ///      forViewer: Bool
        ///
        let file = NXProjectFile()
        file.fileName = "1-2017-02-21-08-16-02.txt.nxl"
        file.filePath = "/1-2017-02-21-08-16-02.txt.nxl"
        file.projectId = "25"
        let toFolder = "/Users/pchen/Desktop/"
        let length: Int64 = 16896
        projectService.downlodFile(file: file, toFolder: toFolder, start: 0, length: length, forViewer: false)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testCancelDownloadFile() {
        let file = NXProjectFile()
        file.fileName = "1-2017-02-21-08-16-02.txt.nxl"
        file.filePath = "/1-2017-02-21-08-16-02.txt.nxl"
        file.projectId = "25"
        let toFolder = "/Users/pchen/Desktop/"
        let length: Int64 = 16896
        projectService.downlodFile(file: file, toFolder: toFolder, start: 0, length: length, forViewer: false)
        
        XCTAssertTrue(projectService.cancelDownloadFile(file: file, localFolder: toFolder))
    }

    func testProjectInvitation() {
        let project = NXProject()
        project.projectId = "25"
        
        var members = [NXProjectMember]()
        let member = NXProjectMember()
        member.email = "paul.chen@nextlabs.com"
        members.append(member)
        
        projectService.projectInvitation(project: project, members: members)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testAcceptInvitation() {
        let invitation = NXProjectInvitation()
        invitation.invitationId = "92"
        invitation.code = "70C3786D1D1D548763AF0E319489484FFA7B9F0A527BFDD24E8F596037ABD0C3"
        projectService.acceptInvitation(invitation: invitation)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }
    
    func testDeclineInvitation() {
        
        let invitation = NXProjectInvitation()
        invitation.invitationId = "82"
        invitation.code = "B8F1CBD55E4687DB8A4B63CBE538A06EFB0C08912E74F3AE5A4871EC7683BA35"
        
        let declineReason = "not happy"
        
        projectService.declineInvitation(invitation: invitation, declineReason: declineReason)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testListMember() {
        ///
        /// Parameter include:
        ///      projectId: Int
        ///      page: Int
        ///      size: Int
        ///      orderBy: Array
        ///      picture: Bool
        ///      q: []
        ///      searchString: String
        ///
        let project = NXProject()
        project.projectId = "25"
        let filter = NXProjectMemberFilter(page: "1", size: "10", orderBy: [NXProjectMemberSortType.createTime(isAscend: true)], picture: false, q: [NXProjectSearchFieldType.email], searchString: "p")
        projectService.listMember(project: project, filter: filter)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testRemoveMember() {

        let project = NXProject()
        project.projectId = "25"
        
        let member = NXProjectMember()
        member.userId = "40"
        projectService.removeMember(project: project, member: member)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testGetMemberDetails() {
        let project = NXProject()
        project.projectId = "25"
        
        let member = NXProjectMember()
        member.userId = "40"
        
        projectService.getMemberDetails(project: project, member: member)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }

    func testListPendingInvitationForProject() {
        ///
        /// Parameter include:
        ///      projectId: Int
        ///      page: Int
        ///      size: Int
        ///      orderBy: Array
        ///      q: []
        ///      searchString: String
        ///
        let project = NXProject()
        project.projectId = "25"
        let filter = NXProjectPendingInvitationFilter(page: "1", size: "10", orderBy: [NXProjectMemberSortType.createTime(isAscend: true)], q: [NXProjectSearchFieldType.email], searchString: "q")
        projectService.listPendingInvitationForProject(project: project, filter: filter)
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }
    
    func testListPendingInvitationForUser() {
        projectService.listPendingInvitationForUser()
        
        expection = expectation(description: "")
        waitForExpectations(timeout: Constants.timeout) { error in
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

}


extension NXProjectServiceTests: NXProjectServiceDelegate {
    
    func listProjectFinish(listType: NXListProjectType, projectList: [NXProject]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func getProjectMetadataFinish(projectId: String, project: NXProject?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    // MARK: Project File Operation
    func uploadFileFinish(projectId: String, from: String, to: String?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func listFileFinish(projectId: String, filter: NXProjectFileFilter, fileList: [NXProjectFile]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func createFolderFinish(projectId: String, servicePath: String, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func deleteFileFinish(projectId: String, servicePath: String, isFolder: Bool, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func getFileMetadataFinish(projectId: String, servicePath: String, file: NXProjectFile?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func searchFileFinish(projectId: String, query: String, fileList: [NXProjectFile]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func downloadFileFinish(projectId: String, from: String, to: String, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func downloadFileProgress(projectId: String, servicePath: String, progress: Double) {
    }
    
    // MARK: Project Member Operation
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func acceptInvitationFinish(invitation: NXProjectInvitation, projectId: String?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func declineInvitationFinish(invitation: NXProjectInvitation, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func listMemberFinish(projectId: String, filter: NXProjectMemberFilter, memberList: [NXProjectMember]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func removeMemberFinish(projectId: String, member: NXProjectMember, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func getMemberDetailsFinish(projectId: String, member: NXProjectMember?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func listPendingInvitationForProjectFinish(projectId: String, filter: NXProjectPendingInvitationFilter, pendingList:  [NXProjectInvitation]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
    func listPendingInvitationForUserFinish(pendingList: [NXProjectInvitation]?, error: Error?) {
        XCTAssertNil(error)
        expection?.fulfill()
    }
    
}
