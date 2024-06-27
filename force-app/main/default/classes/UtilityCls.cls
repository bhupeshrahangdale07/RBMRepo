  /** 
 *  @description This class is used for providing utility methods.
 * Version#     Date                            Author                                  Description
 * --------------------------------------------------------------------------------------------------------------
 * 1.0         08-09-2023                     Kandisa Technologies                    Initial Version 1.0
 * --------------------------------------------------------------------------------------------------------------
 */
public class UtilityCls {
	
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
        Set<string> contentDocIds = new Set<string>();
        Map<ID, rbin__Deleted_Data__c> mapDeletedDeteRec = new Map<ID, rbin__Deleted_Data__c>([SELECT Id FROM rbin__Deleted_Data__c Where rbin__Record_ID__c In :recIds]);
        List<ContentDocumentLink> cdlRecords = [SELECT ContentDocumentId from ContentDocumentLink where LinkedEntityId In :mapDeletedDeteRec.keySet()];
        for (ContentDocumentLink cdl : cdlRecords) {
            contentDocIds.add(cdl.ContentDocumentId);
        }
        for (ContentVersion recVersionData : [
            SELECT Id, ContentDocumentId, VersionData, 
            Title FROM ContentVersion WHERE ContentDocumentId In :contentDocIds WITH SECURITY_ENFORCED
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

                        } else if(fieldDescribe.getType() == Schema.DisplayType.base64){

                            String base64Value = String.valueOf(jsonMap.get(fieldName));
                            Blob fieldValue = Blob.valueOf(base64Value);
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
     *  @description Get a list of objects to ignore.
     *
     * @return List of objects to ignore.
     */
    public static List<string> objectsToIgnore () {
        List<String> lstObjectsToIgnore = new List<String>();
        for (rbin__Objects_To_Ignore__mdt obj : [SELECT Id, MasterLabel FROM rbin__Objects_To_Ignore__mdt WITH SECURITY_ENFORCED]) {
            lstObjectsToIgnore.add(obj.MasterLabel);
        }
        return lstObjectsToIgnore;
    }
}