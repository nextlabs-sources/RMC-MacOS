//
//  NXRMCDef.swift
//  skyDRM
//
//  Created by nextlabs on 30/12/2016.
//  Copyright © 2016 nextlabs. All rights reserved.
//

import Foundation
///
//MARK: Login
let DEFAULT_PERSONAL_LOGIN_URL = "https://www.skydrm.com"
let DEFAULT_COMPANY_LOGIN_URL = "example: https://skydrm.microsoft.com"
let DEFAULT_PERSONAL_LOGIN_TenantID = "skydrm.com"
//Get the device version
let SYSTEMINFO = NSDictionary(contentsOf:URL(string:"/System/Library/CoreServices/SystemVersion.plist")!)
let MAC_VERSION = SYSTEMINFO?["ProductVersion"]

//MARK: GoogleDrive ID
let GOOGLEDRIVECLIENTID = "1021466473229-rork58ttus0hg1hul2ka5dti0j0tao4l.apps.googleusercontent.com"
let GOOGLEDRIVECLIENTSECRET = "ZCT7ehv_X7edLzFniipA5-G0"
let GOOGLEDRIVEKEYCHAINITEMLENGTH = 20
//MARK: OneDrive ID
let ONEDRIVECLIENTID = "8ea12ff6-4f3f-4f4d-a727-d02e2be5e15e"
let ONEDRIVESCOPE = ["wl.signin","onedrive.readwrite", "onedrive.appfolder", "wl.offline_access", "openid"]
//MARK: Dropbox ID
let DROPBOXKEY = "3y95f3gtd9hii68"
//MARK:SharepointOnline ID
let SHAREPOINTONLINEKEYCHAINLENGTH = 20

//MARK: Service common alias
let DROPBOX_ALIAS = "Dropbox"
let ONEDRIVE_ALIAS = "OneDrive"
let GOOGLE_DRIVE_ALIAS = "Google Drive"
let MYDRIVE_ALIAS = "MyDrive"

//MARK: Cache
let CACHERMS = "rms_"
let CACHEOPENEDIN = "openedIn"
let CACHEDROPBOX = "dropbox_"
let CACHESHAREPOINT = "sharepoint_"
let CACHESHAREPOINTONLINE = "sharepointonline_"
let CACHEONEDRIVE = "onedrive_"
let CACHEGOOGLEDRIVE = "googledrive_"
let CACHEICLOUDDRIVE = "iCloudDrive"
let CACHESKYDRMBOX = "skydrmbox_"
let CACHEDIRECTORY = "directory.cache"
let CACHEROOTDIR = "root"

let RMC_DEFAULT_SERVICE_ID_UNSET = "SERVICE_ID_UNSET"

let KEYCHAIN_DEVICE_ID = "Nextlabs.iOS.DeviceID"
let KEYCHAIN_ONEDRIVE_FLAG = "Nextlabs.MAC.OneDrive"
let KEY_FIRST_LOGIN_FLAG = "Nextlabs.Mac.FirstLogin"

let NXRMS_ADDRESS_KEY = "NXRMS_ADDRESS_KEY"

let NXSKYDRM_LOGIN_STATE_KEY = "skyDRM_MAC_LOGIN_STATE_KEY"
let NXSKYDRM_LOGIN_REMEMBERED_URL_KEY = "skyDRM_MAC_LOGIN_REMEMBER_URL_KEY"

enum loginStateType :Int32{
    case personal = 1
    case company =  2
}

enum ServiceType : Int32, CustomStringConvertible {
    case kServiceUnset
    case kServiceDropbox
    case kServiceSharepointOnline
    case kServiceSharepoint
    case kServiceOneDrive
    case kServiceGoogleDrive
    case kServiceICloudDrive
    case kServiceSkyDrmBox
    case kServiceMyVault
    
    var description: String {
        switch self {
        case .kServiceDropbox:
            return "Dropbox"
        case .kServiceSharepointOnline:
            return "SharePoint Online"
        case .kServiceSharepoint:
            return "SharePoint"
        case .kServiceOneDrive:
            return "OneDrive"
        case .kServiceGoogleDrive:
            return "Google Drive"
        case .kServiceSkyDrmBox:
            return "MyDrive"
        case .kServiceMyVault:
            return "MyVault"
        default:
            return ""
        }
    }
    var rmsDescription: String {
        switch self {
        case .kServiceDropbox:
            return RMS_REPO_TYPE_DROPBOX
        case .kServiceGoogleDrive:
            return RMS_REPO_TYPE_GOOGLEDRIVE
        case .kServiceOneDrive:
            return RMS_REPO_TYPE_ONEDRIVE
        case .kServiceSharepointOnline:
            return RMS_REPO_TYPE_SHAREPOINTONLINE
        case .kServiceSkyDrmBox:
            return RMS_REPO_TYPE_SKYDRMBOX
        default:
            return ""
        }
    }
    init(rmsDescription: String) {
        switch rmsDescription {
        case RMS_REPO_TYPE_DROPBOX:
            self = .kServiceDropbox
        case RMS_REPO_TYPE_GOOGLEDRIVE:
            self = .kServiceGoogleDrive
        case RMS_REPO_TYPE_ONEDRIVE:
            self = .kServiceOneDrive
        case RMS_REPO_TYPE_SHAREPOINTONLINE:
            self = .kServiceSharepointOnline
        case RMS_REPO_TYPE_SKYDRMBOX:
            self = .kServiceSkyDrmBox
        default:
            self = .kServiceUnset
        }
    }
}

let RMS_REPO_TYPE_SHAREPOINT = "SHAREPOINT_ONPREMISE"
let RMS_REPO_TYPE_SHAREPOINTONLINE = "SHAREPOINT_ONLINE"
let RMS_REPO_TYPE_DROPBOX = "DROPBOX"
let RMS_REPO_TYPE_GOOGLEDRIVE = "GOOGLE_DRIVE"
let RMS_REPO_TYPE_ONEDRIVE = "ONE_DRIVE"
let RMS_REPO_TYPE_SKYDRMBOX = "S3"

//MARK Notification

//let SKYDRM_SHOULD_LOGOUT = "NotifySkyDRMShouldLogOut"
let SKYDRM_TOKEN_EXPIRED = "NotifySkyDRMTokenExpired"

//Mark ActivityLog
let APPLICATION_NAME       =  "RMC MAC"
let APPLICATION_PUBLISHER  =  "NextLabs"
let APPLICATION_PATH       =  "RMC MAC"

//MARK: Error code
let NXHTTPSTATUSERROR = "NXHttpStatusError"
let NXHTTPAUTOREDIRECTERROR = "NXHttpAutoRedirectError"
let NX_ERROR_SERVICEDOMAIN = "NXRMCServicesErrorDomain"
let NX_ERROR_NETWORK_DOMAIN = "NXNetworkErrorDomain"
let NX_ERROR_REST_DOMAIN = "NXRESTErrorDomain"
let NX_ERROR_NXLFILE_DOMAIN = "NXNXFILEDOMAIN"
let NX_ERROR_RENDER_FILE = "NXFileRenderDomain"
let NX_ERROR_REPO_FILE_SYSTEM_DOMAIN = "NXRepoFileSystemDomain"
enum NXRMC_ERROR_CODE: Int{
    case NXRMC_ERROR_CODE_NOSUCHFILE = 10000
    case NXRMC_ERROR_CODE_AUTHFAILED
    case NXRMC_ERROR_CODE_CANCEL
    case NXRMC_ERROR_CODE_CONVERTFILEFAILED
    case NXRMC_ERROR_CODE_CONVERTFILEFAILED_NOSUPPORTED
    case NXRMC_ERROR_CODE_CONVERTFILE_CHECKSUM_NOTMATCHED
    case NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED
    case NXRMC_ERROR_NO_NETWORK
    case NXRMC_ERROR_BAD_REQUEST
    case NXRMC_ERROR_GET_USER_ACCOUNT_INFO_FAILED
    case NXRMC_ERROR_CODE_GET_NO_KEY_BLOB
    case NXRMC_ERROR_CODE_NOT_NXL_FILE
    case NXRMC_ERROR_CODE_TRANS_BYTES_FAILED
    case NXRMC_ERROR_CODE_REST_UPLOAD_FAILED
    case NXRMC_ERROR_CODE_REST_MEMBERSHIP_FAILED
    case NXRMC_ERROR_CODE_REST_MEMBERSHIP_CERTIFICATES_NOTENOUGH
    case NXRMC_ERROR_CODE_SERVICE_ALREADY_AUTHED
    case NXRMC_ERROR_CODE_AUTH_ACCOUNT_NOT_SAME
    case NXRMC_ERROR_CODE_RENDER_FILE_FAILED
    case NXRMC_ERROR_CODE_FILE_ACCESS_DENIED
    case NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED
    
    //nxl file related error, such as encrypt/decrypt
    case NXRMC_ERROR_CODE_NXFILE_ISNXL = 20000
    case NXRMC_ERROR_CODE_NXFILE_ISNOTNXL
    case NXRMC_ERROR_CODE_NXFILE_NO_TOKEN // can not get token from keychain, memory cache.
    case NXRMC_ERROR_CODE_NXFILE_ENCRYPT
    case NXRMC_ERROR_CODE_NXFILE_DECRYPT
    case NXRMC_ERROR_CODE_NXFILE_GETFILETYPE
    case NXRMC_ERROR_CODE_NXFILE_ADDPOLICY
    case NXRMC_ERROR_CODE_NXFILE_GETPOLICY
    case NXRMC_ERROR_CODE_NXFILE_UNKNOWN
    case NXRMC_ERROR_CODE_NXFILE_TOKENINFO
    case NXRMC_ERROR_CODE_NXFILE_OWNER
    case NXRMC_ERROR_CODE_NXFILE_DELETED
    
    //file system related error
    case NXRMC_ERROR_CODE_NO_SUCH_REPO = 3000
    
    //download file error
    case NXRMC_ERROR_CODE_PROJECT_NOT_EXIST
}

let SEGMENT_TAG = 101

let MAX_DOWNLOADINGFILES_COUNT = 3

let TABLE_COLUMN_NAME_FIXED_WIDTH = CGFloat(438)
let TABLE_COLUMN_FILELOCATION_FIXED_WIDTH =  CGFloat(90)
let TABLE_COLUMN_DATEMODIFIED_FIXED_WIDTH = CGFloat(156)
let TABLE_COLUMN_SIZE_FIXED_WIDTH = CGFloat(76)
let TABLE_COLUMN_SHAREWITH_FIXED_WIDTH = CGFloat(149)


let BK_COLOR = NSColor(red: 255.0 / 255, green: 255.0 / 255, blue: 255.0 / 255, alpha: 1)
let GREEN_COLOR = NSColor(red: 57.0 / 255, green: 150.0 / 255, blue: 73.0 / 255, alpha: 1)
let BLACK_COLOR = NSColor(red: 0.0 / 255, green: 0.0 / 255, blue: 0.0 / 255, alpha: 1)
let WHITE_COLOR = NSColor(red: 255.0 / 255, green: 255.0 / 255, blue: 255.0 / 255, alpha: 1)
let PROJECT_BK_WHITE_COLOR = NSColor(red: 255.0 / 255, green: 255.0 / 255, blue: 255.0 / 255, alpha: 0.5)

