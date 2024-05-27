  /** 
 *  @description This class is used for providing utility methods.
 * Version#     Date                            Author                                  Description
 * --------------------------------------------------------------------------------------------------------------
 * 1.0         08-09-2023                     Kandisa Technologies                    Initial Version 1.0
 * --------------------------------------------------------------------------------------------------------------
 */
public with sharing class UtilityCls {
	
      /** 
     *  @description Deserialize JSON data and use it to restore in SFDC.
     *
     * @param recIds - List of record IDs.
     * @return List of SObjects to restore.
     */
    public static List<Sobject> sObjectsToRestore(List<String> recIds) {

        List<Sobject> sobjecttoUndeleteList = new List<Sobject>();
        Map<String, String> mapVersionData = new Map<String, String>();
        Integer num1 = 1;
        Integer num0 = 0;
        
        String vData = '';
        for (ContentVersion recVersionData : [
            SELECT Id, ContentDocumentId, VersionData, 
            Title FROM ContentVersion WHERE Title = :recIds WITH SECURITY_ENFORCED
        ]) {
            vData = (recVersionData.VersionData).toString();
            mapVersionData.put(recVersionData.Title, vData);
        }
		
        Map<String, Schema.SObjectField> allMap = new Map<String, Schema.SObjectField>();
        Map<String, Object> jsonMap = new Map<String, Object>();
       
        for (rbin__Deleted_Data__c rec : [
            SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, 
            rbin__Record_Name__c FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c IN :recIds WITH SECURITY_ENFORCED
        ]) {
            jsonMap = (Map<String, Object>) JSON.deserializeUntyped(mapVersionData.get(rec.rbin__Record_ID__c));
            Sobject obj = Schema.getGlobalDescribe().get(rec.rbin__Object_Name__c).newSObject();
            allMap = fetchObjectFieldMap(rec.rbin__Object_Name__c);
            
            for (String fieldName : jsonMap.keySet()) {
                if (fieldName != 'Id'  && allMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = allMap.get(fieldName).getDescribe();
                   
                    if ((fieldDescribe.isAccessible() && fieldDescribe.isCreateable() ) || (fieldDescribe.getRelationshipOrder() == 1 || fieldDescribe.getRelationshipOrder() == 0)) {
                            
                        if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                            Date fieldValue = Date.valueOf(String.valueOf(jsonMap.get(fieldName)));
                            obj.put(fieldName, fieldValue);
                        } else if(fieldDescribe.getType() == Schema.DisplayType.DateTime){
                            String dateField = String.valueOf(jsonMap.get(fieldName));
                            DateTime fieldValue = DateTime.valueOf(dateField.replace('T',' '));
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
        return sobjecttoUndeleteList;
    }

    /**
     *  @description Return object fields.
     *
     * @param sObjectName - Name of the Salesforce object.
     * @return Map of object fields.
     */
    public static Map<String, Schema.SObjectField> fetchObjectFieldMap(String sObjectName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objSchema = schemaMap.get(sObjectName);
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
        return fieldMap;
    }

    /**
     *  @description Return object key fields.
     *
     * @return Map of object key fields.
     */
    public static Map<String, String> fetchObjectKeyFields() {
        Map<String, String> objectKeyFieldMap = new Map<String, String>();

        for (rbin__ObjectKeyField__mdt objectKeyFieldMdt : [
            SELECT Id, MasterLabel, rbin__Field_Name__c
            FROM rbin__ObjectKeyField__mdt WITH SECURITY_ENFORCED
        ]) {
            objectKeyFieldMap.put(objectKeyFieldMdt.MasterLabel, objectKeyFieldMdt.rbin__Field_Name__c);
        }
        return objectKeyFieldMap;
    }
	
     /**
     *  @description Create an attachment to store record data for the deleted record.
     *
     * @param mapDeletedData - Map of deleted record data.
     * @param setRecIds - Set of record IDs.
     */
    public static void createFileAttachment(Map<String, String> mapDeletedData, Set<String> setRecIds) {
        List<ContentDocument> existedContentDoc = [SELECT Id, Title FROM ContentDocument WHERE Title IN :setRecIds WITH SECURITY_ENFORCED];
        // Ensure CRUD permissions on ContentDocument object
        if (Schema.sObjectType.ContentDocument.isdeletable()) {
            Delete existedContentDoc;
        }
        if(existedContentDoc.size() > 0){
            Database.EmptyRecyclebin(existedContentDoc);
        }
       

        Map<String, Id> mapContentVersion = new Map<String, Id>();
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocLnk = new List<ContentDocumentLink>();

        for (rbin__Deleted_Data__c insertedDeletedData : [
            SELECT Id, rbin__Record_ID__c
            FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c IN :mapDeletedData.keySet() WITH SECURITY_ENFORCED
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
        
             // Ensure CRUD permissions on ContentVersion object
        if (lstContentVersion.size() > 0 && Schema.sObjectType.ContentVersion.isCreateable()) {
            Insert lstContentVersion;    
        }  
        
        
        for (ContentVersion cv : [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Title IN :mapContentVersion.keySet() WITH SECURITY_ENFORCED]) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = mapContentVersion.get(cv.Title);
            cdl.ShareType = 'V';
            lstContentDocLnk.add(cdl);
        }
        
             // Ensure CRUD permissions on ContentDocumentLink object
        if (lstContentDocLnk.size() > 0 && Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            Insert lstContentDocLnk;   
        } 
        
    }

     /**
     *  @description Get a list of objects to ignore.
     *
     * @return List of objects to ignore.
     */
    public static List<string> objectsToIgnore () {
        List<String> lstObjectsToIgnore = new List<String>();
        for (rbin__Ignored_Objects__c obj : [Select Id, Name FROM rbin__Ignored_Objects__c WITH SECURITY_ENFORCED]) {
            lstObjectsToIgnore.add(obj.Name);
        }
        return lstObjectsToIgnore;
    }
}