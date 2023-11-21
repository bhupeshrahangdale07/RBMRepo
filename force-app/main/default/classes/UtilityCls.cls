/*
// --------------------------------------------------------------------------------------------------------------

// This class is used to generic methods.
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         08-09-2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/
public with sharing class UtilityCls {

    public static List<Sobject> sObjectsToRestore(Set<String> recIds) {
        List<Sobject> sobjecttoUndeleteList = new List<Sobject>();
        Map<String, String> mapVersionData = new Map<String, String>();
        //Map<String, Id> mapMasterFieldValue = new Map<String, Id>();
        
        for (ContentVersion recVersionData : [
            SELECT Id, ContentDocumentId, VersionData, 
            Title FROM ContentVersion WHERE Title = :recIds
        ]) {
            String vData = (recVersionData.VersionData).toString();
            mapVersionData.put(recVersionData.Title, vData);
        }
		
        //Set<String> allFieldName = new Set<String>();
        Map<String, Object> jsonMap = new Map<String, Object>();
       
        for (rbin__Deleted_Data__c rec : [
            SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, 
            rbin__Record_Name__c FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c IN :recIds
        ]) {
            Map<String, Schema.SObjectField> allMap = new Map<String, Schema.SObjectField>();
            jsonMap = (Map<String, Object>) JSON.deserializeUntyped(mapVersionData.get(rec.rbin__Record_ID__c));
            Sobject obj = Schema.getGlobalDescribe().get(rec.rbin__Object_Name__c).newSObject();
            allMap = fetchObjectFieldMap(rec.rbin__Object_Name__c);
            
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
            //allFieldName = null;
            allMap = null;
        }
        return sobjecttoUndeleteList;
    }

    // Return object fields
    public static Map<String, Schema.SObjectField> fetchObjectFieldMap(String sObjectName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objSchema = schemaMap.get(sObjectName);
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
        return fieldMap;
    }

    // Return object key fields
    public static Map<String, String> fetchObjectKeyFields() {
        Map<String, String> objectKeyFieldMap = new Map<String, String>();

        for (rbin__ObjectKeyField__mdt objectKeyFieldMdt : [
            SELECT Id, MasterLabel, rbin__Field_Name__c
            FROM rbin__ObjectKeyField__mdt
        ]) {
            objectKeyFieldMap.put(objectKeyFieldMdt.MasterLabel, objectKeyFieldMdt.rbin__Field_Name__c);
        }
        return objectKeyFieldMap;
    }

    public static void createFileAttachment(Map<String, String> mapDeletedData, Set<String> setRecIds) {
        List<ContentDocument> existedContentDoc = [SELECT Id, Title FROM ContentDocument WHERE Title IN :setRecIds];
        Delete existedContentDoc;

        Map<String, Id> mapContentVersion = new Map<String, Id>();
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocLnk = new List<ContentDocumentLink>();

        for (rbin__Deleted_Data__c insertedDeletedData : [
            SELECT Id, rbin__Record_ID__c
            FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c IN :mapDeletedData.keySet()
        ]) {
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S';
            cVersion.PathOnClient = insertedDeletedData.rbin__Record_ID__c + '.txt';
            cVersion.Origin = 'H';
            cVersion.Title = insertedDeletedData.rbin__Record_ID__c;
            Blob body = Blob.valueOf(mapDeletedData.get(insertedDeletedData.rbin__Record_ID__c));
            cVersion.VersionData = body;
            lstContentVersion.add(cVersion);
            mapContentVersion.put(cVersion.Title, insertedDeletedData.Id);
        }
        
        if(lstContentVersion.size() > 0){
        	Insert lstContentVersion;    
        }
        
        for (ContentVersion cv : [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Title IN :mapContentVersion.keySet()]) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = mapContentVersion.get(cv.Title);
            cdl.ShareType = 'V';
            lstContentDocLnk.add(cdl);
        }
        
        if(lstContentDocLnk.size() > 0){
        	Insert lstContentDocLnk;   
        }
    }
}