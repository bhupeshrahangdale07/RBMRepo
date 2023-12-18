/*
// --------------------------------------------------------------------------------------------------------------

// This Batch class used to restore the Permanent Delete records for Restore All functionality for more than 1000 records

// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0          11/9/2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/
public class BatchMassRestoreAllPrmntDeleted implements Database.Batchable<sObject> {

    List<String> lstIds;

    public BatchMassRestoreAllPrmntDeleted(List<String> idsList) {
        this.lstIds = idsList;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator('SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c FROM rbin__Deleted_Data__c WHERE rbin__Record_ID__c IN :lstIds');
    }

    public void execute(Database.BatchableContext bc, List<rbin__Deleted_Data__c> lstRecords) {
        Set<String> allFieldName = new Set<String>();
        List<SObject> sobjecttoUndeleteList = new List<SObject>();
        List<rbin__Deleted_Data__c> allRecordList = new List<rbin__Deleted_Data__c>();
        List<rbin__Deleted_Data__c> recordtoDelete = new List<rbin__Deleted_Data__c>();
        Set<String> setDeletedRecIds = new Set<String>();
        Map<String, String> mapVersionData = new Map<String, String>();
        Set<String> setRecordIdsToPurge = new Set<String>();

        for (rbin__Deleted_Data__c rec : lstRecords) {
            setDeletedRecIds.add(rec.rbin__Record_ID__c);
            setRecordIdsToPurge.add(rec.Id);
        }

        for (ContentVersion recVersionData : [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE Title IN :setDeletedRecIds]) {
            String versionDataToString = (recVersionData.VersionData).toString();
            mapVersionData.put(recVersionData.Title, versionDataToString);
        }

        for (rbin__Deleted_Data__c lst : lstRecords) {
            Map<String, Schema.SObjectField> allMap = new Map<String, Schema.SObjectField>();
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(mapVersionData.get(lst.rbin__Record_ID__c));
            allRecordList.add(lst);
            SObject obj = Schema.getGlobalDescribe().get(lst.rbin__Object_Name__c).newSObject();
            allMap = UtilityCls.fetchObjectFieldMap(lst.rbin__Object_Name__c);
            
            for (String fieldName : jsonMap.keySet()) {
                if (fieldName != 'Id'  && allMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = allMap.get(fieldName).getDescribe();
                    if ((fieldDescribe.isCreateable() && fieldDescribe.isUpdateable()) 
                        || (fieldDescribe.getRelationshipOrder() == 1 || fieldDescribe.getRelationshipOrder() == 0)) {
                        if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                            Date fieldValue = Date.valueOf(String.valueOf(jsonMap.get(fieldName)));
                            obj.put(fieldName, fieldValue);
                        } else {
                            obj.put(fieldName, jsonMap.get(fieldName));
                        }
                    }
                } 
            }
            
            sobjecttoUndeleteList.add(obj);
            allMap = null;
        }

        // Add restored DateTime
        TimeZone tz = UserInfo.getTimeZone();
        DateTime dt = Datetime.now();
        DateTime currentDt = dt.addSeconds((tz.getOffset(dt) / 1000));

        Database.SaveResult[] srList = Database.insert(sobjecttoUndeleteList, false);
        List<rbin__Error_Log__c> lstErrorRecords = new List<rbin__Error_Log__c>();
        for (Integer i = 0; i < srList.size(); i++) {
            if (srList[i].isSuccess()) {
                rbin__Deleted_Data__c deleteRecord = allRecordList[i];
                deleteRecord.rbin__Restored_Record_Id__c = srList[i].getId();
                deleteRecord.rbin__Has_Restored__c = true;
                deleteRecord.rbin__Restored_Date_Time__c = currentDt;
                recordtoDelete.add(deleteRecord);
            } else {
                rbin__Error_Log__c errorObj = new rbin__Error_Log__c();
                errorObj.rbin__Error_Message__c = String.valueOf(srList[i].getErrors());
                errorObj.rbin__Failed_Record__c = String.valueOf(sobjecttoUndeleteList[i]);
                lstErrorRecords.add(errorObj);
                rbin__Deleted_Data__c deleteRecord = allRecordList[i];
                deleteRecord.rbin__Has_Restored__c = false;
                recordtoDelete.add(deleteRecord);
            }
        }
        
        
        insert lstErrorRecords;
        Database.update(recordtoDelete, false);
        Database.delete(recordtoDelete, false);
        List<rbin__Deleted_Data__c> lstDeletedRecords = [Select Id, Name From rbin__Deleted_Data__c Where isDeleted = true AND Id IN :setRecordIdsToPurge ALL ROWS];
        Database.EmptyRecyclebin(lstDeletedRecords);
    }

    public void finish(Database.BatchableContext bc) {
        // Add finish logic if needed
        
    }
}