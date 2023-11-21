public with sharing class permanentDeletedRecordPreviewController {

    @AuraEnabled(cacheable = true)
    public static wrpDeletedData showPreviewPage(Id recordId) {
        wrpDeletedData objwrpDeletedData = new wrpDeletedData();
        List<wrpRecordDetail> lstDeletedRecord = new List<wrpRecordDetail>();
        rbin__Deleted_Data__c deletedRecord = [
            SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c
            FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c = :recordId
            LIMIT 1
        ];
        ContentVersion cv = [
            SELECT Id, ContentDocumentId, VersionData, Title
            FROM ContentVersion
            WHERE Title = :recordId
        ];

        String deletedData = (cv.VersionData).toString();
        String objName = (String) Schema.getGlobalDescribe().get(deletedRecord.rbin__Object_Name__c).getDescribe().getLabel();
        String recName = deletedRecord.rbin__Record_Name__c;

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(deletedRecord.rbin__Object_Name__c).getDescribe().fields.getMap();

        for (String key : jsonMap.keySet()) {
            if (key != 'attributes' && key != 'BillingAddress' && key != 'ShippingAddress' && key != 'MailingAddress') {
                wrpRecordDetail objwr = new wrpRecordDetail();
                objwr.FieldLabel = fieldMap.get(key).getDescribe().getLabel();
                System.debug('Label- ' + objwr.FieldLabel);
                if (jsonMap.get(key) != null) {
                    System.debug('Value- ' + String.valueOf(jsonMap.get(key)));
                    objwr.Value = String.valueOf(jsonMap.get(key));
                } else {
                    objwr.Value = '-';
                }
                lstDeletedRecord.add(objwr);
            }
        }

        objwrpDeletedData.lstWrpData = lstDeletedRecord;
        objwrpDeletedData.objectName = objName;
        objwrpDeletedData.recordName = recName;

        return objwrpDeletedData;
    }

    @AuraEnabled
    public static wrpDeletedData restoreRecord(Id recordId) {
        try {
            Set<String> allFieldName = new Set<String>();
            rbin__Deleted_Data__c previewRecord = [
                SELECT Id, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Record_Name__c
                FROM rbin__Deleted_Data__c
                WHERE rbin__Record_ID__c = :recordId
                LIMIT 1
            ];
            ContentVersion cv = [
                SELECT Id, ContentDocumentId, VersionData, Title
                FROM ContentVersion
                WHERE Title = :recordId
            ];

            String deletedData = (cv.VersionData).toString();
            String objName = previewRecord.rbin__Object_Name__c;
            String recName = previewRecord.rbin__Record_Name__c;
            wrpDeletedData recWrapData = new wrpDeletedData();
            SObject obj = Schema.getGlobalDescribe().get(objName).newSObject();
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);

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

            TimeZone tz = UserInfo.getTimeZone();
            DateTime dt = Datetime.now();
            DateTime currentDt = dt.addSeconds((tz.getOffset(dt) / 1000));

                Database.SaveResult sr = Database.insert(obj, false);
                Id recId;
                if (sr.isSuccess()) {
                    // Record was successfully inserted
                    recId = sr.getId();
                    previewRecord.rbin__Restored_Record_Id__c = sr.getId();
                    previewRecord.rbin__Has_Restored__c = true;
                    //previewRecord.rbin__Restored_Date_Time__c =currentDt;
                        update previewRecord;
                        delete previewRecord;
                        recWrapData.recordId = recId;
                       // return recId;
                } else {
                    // Handle errors
                    for (Database.Error error : sr.getErrors()) {
                        System.debug('Error message: ' + error.getMessage());
                        System.debug('Error field: ' + error.getFields());
                        recWrapData.errorMessage = error.getMessage();
                    }
                    //return recId;
                }

                return recWrapData;
                    // return sr.getId();
        
            
       } catch (Exception e) {
        system.debug('In catch handler');
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class wrpDeletedData {
        @AuraEnabled
        public List<wrpRecordDetail> lstWrpData = null;
        @AuraEnabled
        public String objectName { get; set; }
        @AuraEnabled
        public String recordName { get; set; }
        @AuraEnabled
        public Id recordId { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
    }

    public class wrpRecordDetail {
        @AuraEnabled
        public String FieldLabel { get; set; }
        @AuraEnabled
        public String Value { get; set; }

        public wrpRecordDetail() {
            FieldLabel = '';
            Value = '';
        }
    }
}