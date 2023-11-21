public class BatchMassRestoreAllPrmntDeleted implements Database.Batchable<sObject> {

    List<String> lstIds;

    public BatchMassRestoreAllPrmntDeleted(List<String> idsList) {
        this.lstIds = idsList;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('lstIds--->>>'+lstIds);
        return Database.getQueryLocator('SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c FROM rbin__Deleted_Data__c WHERE rbin__Record_ID__c IN :lstIds');
    }

    public void execute(Database.BatchableContext bc, List<rbin__Deleted_Data__c> lstRecords) {
        Set<String> allFieldName = new Set<String>();
        List<SObject> sobjecttoUndeleteList = new List<SObject>();
        List<rbin__Deleted_Data__c> allRecordList = new List<rbin__Deleted_Data__c>();
        List<rbin__Deleted_Data__c> recordtoDelete = new List<rbin__Deleted_Data__c>();
        Set<String> setDeletedRecIds = new Set<String>();
        Map<String, String> mapVersionData = new Map<String, String>();

        for (rbin__Deleted_Data__c rec : lstRecords) {
            setDeletedRecIds.add(rec.rbin__Record_ID__c);
        }

        for (ContentVersion recVersionData : [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE Title IN :setDeletedRecIds]) {
            String versionDataToString = (recVersionData.VersionData).toString();
            mapVersionData.put(recVersionData.Title, versionDataToString);
        }

        for (rbin__Deleted_Data__c lst : lstRecords) {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(mapVersionData.get(lst.rbin__Record_ID__c));
            allRecordList.add(lst);
            SObject obj = Schema.getGlobalDescribe().get(lst.rbin__Object_Name__c).newSObject();
            Map<String, Schema.SObjectField> allMap = obj.getSObjectType().getDescribe().fields.getMap();

            for (Schema.SObjectField field : allMap.values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if (dfr.isCreateable() && dfr.isUpdateable()) {
                    allFieldName.add(dfr.getName());
                } else if (dfr.getRelationshipOrder() == 1 || dfr.getRelationshipOrder() == 0) {
                    allFieldName.add(dfr.getName());
                }
            }
            
            for (String fieldName : jsonMap.keySet()) {
                if (allFieldName.contains(fieldName) && fieldName != 'Id') {
                    Schema.DescribeFieldResult fieldDescribe = allMap.get(fieldName).getDescribe();
                    if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                        Date fieldValue = Date.valueOf(String.valueOf(jsonMap.get(fieldName)));
                        obj.put(fieldName, fieldValue);
                    } else {
                        obj.put(fieldName, jsonMap.get(fieldName));
                    }
                }
            }
            
            sobjecttoUndeleteList.add(obj);
        }

        // Add restored DateTime
        TimeZone tz = UserInfo.getTimeZone();
        DateTime dt = Datetime.now();
        DateTime currentDt = dt.addSeconds((tz.getOffset(dt) / 1000));

        Database.SaveResult[] srList = Database.insert(sobjecttoUndeleteList, false);

        for (Integer i = 0; i < srList.size(); i++) {
            if (srList[i].isSuccess()) {
                rbin__Deleted_Data__c deleteRecord = allRecordList[i];
                deleteRecord.rbin__Restored_Record_Id__c = srList[i].getId();
                deleteRecord.rbin__Has_Restored__c = true;
                deleteRecord.rbin__Restored_Date_Time__c = currentDt;
                recordtoDelete.add(deleteRecord);
            } else {
                System.debug('Error while saving the record- ' + srList[i].getErrors());
            }
        }

        Database.update(recordtoDelete, false);
        Database.delete(recordtoDelete, false);
    }

    public void finish(Database.BatchableContext bc) {
        // Add finish logic if needed
    }
}