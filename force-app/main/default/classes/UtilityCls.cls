/*
// --------------------------------------------------------------------------------------------------------------

// This class is used to generic methods.
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         08-09-2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/
public with sharing class UtilityCls {
	
    //TODO: change the method name
    public static List<Sobject> sObjectsToRestore(Set<String> recIds){

        List<Sobject> sobjecttoUndeleteList = new List<Sobject>();
        set<String> allFieldName = new set<String>();
        Map<string,string> mapVersionData= new Map<string,string>();
        for(ContentVersion recVersionData:[SELECT Id, ContentDocumentId,VersionData,Title FROM ContentVersion WHERE Title =:recIds]){
                     string vData = (recVersionData.VersionData).toString();
                     mapVersionData.put(recVersionData.Title,vData);
        }
        
        for(rbin__Deleted_Data__c rec : [Select id, rbin__Data__c, rbin__Record_ID__c, rbin__Object_Name__c,rbin__Record_Name__c from rbin__Deleted_Data__c where rbin__Record_ID__c in :recIds]){
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(mapVersionData.get(rec.rbin__Record_ID__c));
            Sobject obj = Schema.getGlobalDescribe().get(rec.rbin__Object_Name__c).newSObject();
            Map<String, Schema.SobjectField> allMap = obj.getSObjectType().getDescribe().fields.getMap();
            
            for(Schema.SobjectField field : allMap.values()){
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if(dfr.isCreateable() && dfr.isUpdateable()){
                    allFieldName.add(dfr.getName());
                }else if(dfr.getRelationshipOrder() == 1 || dfr.getRelationshipOrder() == 0){
                    allFieldName.add(dfr.getName());
                }
            }
            
            for(String fieldName:jsonMap.keySet()){
                
                if (allFieldName.contains(fieldName) && fieldName != 'Id') {
                    Schema.DescribeFieldResult fieldDescribe = allMap.get(fieldName).getDescribe();
                    if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                        Date fieldValue = Date.valueOf(String.valueOf(jsonMap.get(fieldName)));
                        obj.put(fieldName, fieldValue);
                    } else {
                        system.debug('Name of Field-'+fieldName);
                        obj.put(fieldName, jsonMap.get(fieldName));
                    }
                }
            }
            
            allFieldName = null;
            sobjecttoUndeleteList.add(obj);
        }
        return sobjecttoUndeleteList;
    }
    
    //return object fields
    public static Map<String, Schema.SObjectField> fetchObjectFieldMap(String sObjectName){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objSchema = schemaMap.get(sObjectName);
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
        return fieldMap;
    }
    
    //return object key fields
    public static Map<string,string> fetchObjectKeyFields(){
        Map<string,string> objectKeyFieldMap = new Map<string,string>();
        
        for(rbin__ObjectKeyField__mdt objectKeyFieldMdt : [Select id, MasterLabel, rbin__Field_Name__c From rbin__ObjectKeyField__mdt]){
            objectKeyFieldMap.put(objectKeyFieldMdt.MasterLabel,objectKeyFieldMdt.rbin__Field_Name__c);
        }
        return objectKeyFieldMap;
    }
}