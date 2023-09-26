public with sharing class UtilClass {
    
    
    public static List<Sobject> createFields(set<string> recIds){
        try {
            system.debug('In util class');
            List<Sobject> sobjecttoUndeleteList = new List<Sobject>();
            set<String> allFieldName = new set<String>();
            for(rbin__Deleted_Data__c rec:[select id,rbin__Data__c,rbin__Record_ID__c,rbin__Object_Name__c,rbin__Record_Name__c from rbin__Deleted_Data__c where rbin__Record_ID__c in: recIds]){
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(rec.rbin__Data__c);
                Sobject obj = Schema.getGlobalDescribe().get(rec.rbin__Object_Name__c).newSObject();
                Map<String, Schema.SobjectField> allMap = obj.getSObjectType().getDescribe().fields.getMap();

            for(Schema.SobjectField field : allMap.values())
            {
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
            //allFieldName = null;
            system.debug('Object- '+obj);
            sobjecttoUndeleteList.add(obj);
        }
        return sobjecttoUndeleteList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}