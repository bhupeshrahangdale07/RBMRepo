
/** 
 *  @description This class is the controller apex class to support the trackPermanentlyDeletedDataTab LWC Component
 * Version#     Date                            Author                                  Description
 * --------------------------------------------------------------------------------------------------------------
 * 1.0         25/8/2023                       Kandisa Technologies                    Initial Version 1.0
 * --------------------------------------------------------------------------------------------------------------
 */

public with sharing class permanentDeletedRecordPreviewController {

    /** 
     *  @description This method get called for preview of the record
     * @param recordId - List of record IDs.
     * @return WrpDeletedData 
     */
    @AuraEnabled(cacheable = true)
    public static WrpDeletedData showPreviewPage(Id recordId) {
        WrpDeletedData objwrpDeletedData = new WrpDeletedData();
        List<WrpRecordDetail> lstDeletedRecord = new List<WrpRecordDetail>();
        rbin__Deleted_Data__c deletedRecord = [
            SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c
            FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c = :recordId
             WITH SECURITY_ENFORCED LIMIT 1
        ];
        // will get the JSON data of the record from ContentVersion
        ContentVersion cv = [
            SELECT Id, ContentDocumentId, VersionData, Title
            FROM ContentVersion
            WHERE Title = :recordId WITH SECURITY_ENFORCED
        ];

        String deletedData = (cv.VersionData).toString();
        String objName = (String) Schema.getGlobalDescribe().get(deletedRecord.rbin__Object_Name__c).getDescribe().getLabel();
        String recName = deletedRecord.rbin__Record_Name__c;

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);// Deserialize the JSON Data of a record

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(deletedRecord.rbin__Object_Name__c).getDescribe().fields.getMap();

        for (String key : jsonMap.keySet()) {
            if (key != 'attributes' && key != 'BillingAddress' && key != 'ShippingAddress' && key != 'MailingAddress') {
                WrpRecordDetail objwr = new WrpRecordDetail();
                objwr.fieldLabel = fieldMap.get(key).getDescribe().getLabel();
                if (jsonMap.get(key) != null) {
                    objwr.value = String.valueOf(jsonMap.get(key));
                } else {
                    objwr.value = '-';
                }
                lstDeletedRecord.add(objwr);
            }
        }

        objwrpDeletedData.lstWrpData = lstDeletedRecord;
        objwrpDeletedData.objectName = objName;
        objwrpDeletedData.recordName = recName;

        return objwrpDeletedData;
    }

     /** 
     *  @description This method will restore the record on restore button click
     *  @param recordId - ID of the record to be restored.
     *  @return Id - Restored record Id
     */
    @AuraEnabled
    public static Id restoreRecord(Id recordId) {
        try {
            rbin__Deleted_Data__c previewRecord = [
                SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c
                FROM rbin__Deleted_Data__c
                WHERE rbin__Record_ID__c = :recordId
                 WITH SECURITY_ENFORCED LIMIT 1
            ];
            ContentVersion cv = [
                SELECT Id, ContentDocumentId, VersionData, Title
                FROM ContentVersion
                WHERE Title = :recordId WITH SECURITY_ENFORCED
            ];

            String deletedData = (cv.VersionData).toString();
            String objName = previewRecord.rbin__Object_Name__c;
            String recIdsToPurge = previewRecord.Id;
            SObject obj = Schema.getGlobalDescribe().get(objName).newSObject();// create a object instance for restoring
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);
            Map<String, Schema.SObjectField> allMap = new Map<String, Schema.SObjectField>();
            
            allMap = UtilityCls.fetchObjectFieldMap(previewRecord.rbin__Object_Name__c);// this will return map of all field api name and sObjectField
            
            for (String fieldName : jsonMap.keySet()) {

                if (fieldName != 'Id'  && allMap.containsKey(fieldName)) {

                    Schema.DescribeFieldResult fieldDescribe = allMap.get(fieldName).getDescribe();
                    if ((fieldDescribe.isAccessible() && fieldDescribe.isCreateable()) 
                        || (fieldDescribe.getRelationshipOrder() == 1 || fieldDescribe.getRelationshipOrder() == 0)) {

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

            // TimeZone tz = UserInfo.getTimeZone();
            // DateTime dt = Datetime.now();
            // DateTime currentDt = dt.addSeconds((tz.getOffset(dt) / 1000));

                Database.SaveResult sr = Database.insert(obj, true);
                Id recId;
                if (sr.isSuccess()) {
                    // Record was successfully inserted
                    recId = sr.getId();
                    // previewRecord.rbin__Restored_Record_Id__c = sr.getId();
                    // previewRecord.rbin__Has_Restored__c = true;
                    // previewRecord.rbin__Restored_Date_Time__c =currentDt;
                    if(Schema.sObjectType.rbin__Deleted_Data__c.isdeletable()){
                        //update previewRecord;
                        delete previewRecord;
                    }
                        
                        List<rbin__Deleted_Data__c> lstDeletedRecords = [Select Id, Name From rbin__Deleted_Data__c Where isDeleted = true AND Id = :recIdsToPurge WITH SECURITY_ENFORCED ALL ROWS];
        Database.EmptyRecyclebin(lstDeletedRecords);
                         
                } 
                return recId;
               // return null;
        

       } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 /** 
     *  @description This wrapper class is used for WrpRecordDetail, object Name. Record Name and RecordId
     */
    public class WrpDeletedData {
        @AuraEnabled
        public List<WrpRecordDetail> lstWrpData = null;
          /**
     * @description The name of the object.
     */
        @AuraEnabled
        public String objectName { get; set; }
            /**
     * @description The name of the record.
     */
        @AuraEnabled
        public String recordName { get; set; }
            /**
     * @description Record Id.
     */
        @AuraEnabled
        public Id recordId { get; set; }
    }
    /** 
     *  @description This wrapper class is used for fieldLabel, value
     */
    public class WrpRecordDetail {
            /**
     * @description fieldLabel.
     */
        @AuraEnabled
        public String fieldLabel { get; set; }
             /**
     * @description field value.
     */
        @AuraEnabled
        public String value { get; set; }

          /**ys
     * @description WrpRecordDetail constructor.
     */
        public WrpRecordDetail() {
            fieldLabel = '';
            value = '';
        }
    }
}