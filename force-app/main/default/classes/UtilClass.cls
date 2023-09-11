public with sharing class UtilClass {
    
    
    public static Sobject createFields(string recordData, string objName){
        try {
            system.debug('In util class');
            set<String> allFieldName = new set<String>();
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(recordData);
                Sobject obj = Schema.getGlobalDescribe().get(objName).newSObject();
                Map<String, Schema.SobjectField> allMap = obj.getSObjectType().getDescribe().fields.getMap();

            for(Schema.SobjectField field : allMap.values())
            {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if(dfr.isCreateable() && dfr.isUpdateable())
                    allFieldName.add(dfr.getName());
            }
            for(String fieldName:jsonMap.keySet()){
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
        return obj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}