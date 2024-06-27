
/** 
 *  @description This Batch class used to restore the Permanent Delete records for Restore All functionality for more than 1000 records
 * Version#     Date                            Author                                  Description
 * --------------------------------------------------------------------------------------------------------------
 * 1.0         11/9/2023                      Kandisa Technologies                    Initial Version 1.0
 * --------------------------------------------------------------------------------------------------------------
 */
public class BatchMassRestoreAllPrmntDeleted implements Database.Batchable<sObject>, Database.Stateful {

    List<String> lstIds;
    Integer totalRecordProcessed = 0;
    Integer totalFailedRecords = 0;
    Integer totalSuccessRecords = 0;
/**
 * @description This constructor is for passinf Id list 
 * @param idsList - List of record ids to restore
 */
    public BatchMassRestoreAllPrmntDeleted(List<String> idsList) {
        this.lstIds = idsList;
    }

    /**
     * @description The start method for getting records to restore
     * @param bc - BatchableContext
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator('SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c FROM rbin__Deleted_Data__c WHERE rbin__Record_ID__c IN :lstIds');
    }

    /**
     * @description execute method which will execute the logic for restoring the records
     * @param bc - batchable context
     * @param lstRecords - List of record Ids to restore
     */
    public void execute(Database.BatchableContext bc, List<rbin__Deleted_Data__c> lstRecords) {
        List<SObject> sobjecttoUndeleteList = new List<SObject>();
        List<rbin__Deleted_Data__c> allRecordList = new List<rbin__Deleted_Data__c>();
        List<rbin__Deleted_Data__c> recordtoDelete = new List<rbin__Deleted_Data__c>();
        Map<String, String> mapVersionData = new Map<String, String>();
        Set<String> setDeletedDataIds = new Set<String>();
        Set<String> setDeletedDataRecIds = new Set<String>();

        for (rbin__Deleted_Data__c rec : lstRecords) {
            setDeletedDataIds.add(rec.Id);
        }

        Set<string> contentDocIds = new Set<string>();
        List<ContentDocumentLink> cdlRecords = [SELECT ContentDocumentId from ContentDocumentLink where LinkedEntityId In :setDeletedDataIds ];
        for (ContentDocumentLink cdl : cdlRecords) {
            contentDocIds.add(cdl.ContentDocumentId);
        }

        for (ContentVersion recVersionData : [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds]) {
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
                    if ((fieldDescribe.isAccessible() && fieldDescribe.isCreateable()) 
                        || (fieldDescribe.getRelationshipOrder() == 1 || fieldDescribe.getRelationshipOrder() == 0)) {
                        if (fieldDescribe.getType() == Schema.DisplayType.DATE) {

                            Date fieldValue = Date.valueOf(String.valueOf(jsonMap.get(fieldName)));
                            obj.put(fieldName, fieldValue);

                        } else if(fieldDescribe.getType() == Schema.DisplayType.DateTime){
                            
                            String dateField = String.valueOf(jsonMap.get(fieldName));
                            DateTime fieldValue = DateTime.valueOf(dateField.replace('T',' '));
                            obj.put(fieldName, fieldValue);

                        } else if(fieldDescribe.getType() == Schema.DisplayType.base64){

                            String base64Value = String.valueOf(jsonMap.get(fieldName));
                            Blob fieldValue = Blob.valueOf(base64Value);
                            obj.put(fieldName, fieldValue);

                        }else{
                            obj.put(fieldName, jsonMap.get(fieldName));
                        }
                    }
                } 
            }
            
            sobjecttoUndeleteList.add(obj);
            allMap = null;
        }

        List<rbin__Error_Log__c> lstErrorRecords = new List<rbin__Error_Log__c>();
        

        Database.SaveResult[] srList = Database.insert(sobjecttoUndeleteList, false);
        
        for (Integer i = 0; i < srList.size(); i++) {

            totalRecordProcessed += 1;
            if (srList[i].isSuccess()) {
                totalSuccessRecords +=1;
                rbin__Deleted_Data__c deleteRecord = allRecordList[i];
                
                recordtoDelete.add(deleteRecord);

            } else {
                totalFailedRecords += 1;
                rbin__Error_Log__c errorObj = new rbin__Error_Log__c();
                errorObj.rbin__Error_Message__c = String.valueOf(srList[i].getErrors());
                errorObj.rbin__Failed_Record__c = String.valueOf(sobjecttoUndeleteList[i]);
                lstErrorRecords.add(errorObj);
                

            }
        
        }
        
        if(Schema.sObjectType.rbin__Error_Log__c.isCreateable()) {

        insert lstErrorRecords;
    }
        Database.delete(recordtoDelete, false);
       
        if(recordtoDelete.size() > 0){
            Database.EmptyRecyclebin(recordtoDelete);
        }
        
    }
    /**
     * @description - finish method
     * @param bc - batchableContext
     */
    public void finish(Database.BatchableContext bc) {
        // Add finish logic if needed
        List<String> sendtomails = new List<String>();
        String UserEmail = UserInfo.getUserEmail();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
            sendtomails.add(UserEmail); // Add email of system admin
        
        email.saveAsActivity = false;
        email.setToAddresses(sendtomails);
        email.setSubject('Batch Restore Records Status');
        
        String body = 'Hi Admin, <br/><br/>' + UserInfo.getName() + ' has processed total ' + totalRecordProcessed + ' for restore. <br/><br/>Below is the details of restored Records,<br/><br/><table border="1" style="border-collapse: collapse; width: 50%; "><tr><th>Description</th><th>Count</b>&nbsp;&nbsp;';
        
        body += '</th></tr><tr style = "text-align: center;"><td>Success Records &nbsp;&nbsp;</td><td>&nbsp;&nbsp;' + totalSuccessRecords + '</td></tr><tr style="text-align: center;"><td>Failed Records</td><td>&nbsp;&nbsp;'+ totalFailedRecords +'</td></tr></table><br/>';
        
        body += '**Please check the <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+Schema.SObjectType.rbin__Error_Log__c.getKeyPrefix()+'/o'+'">\'Error Log\'</a> for failed records in RBM app.<br/><br/>Thanks,<br/>Recycle Bin Manager';

        email.setHtmlBody(body);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
    }
}