public with sharing class fetchAllObjects {
    
    @AuraEnabled(cacheable = true)
    public static Map<string,string> getAllObjectName(){
        try {
            Map<string,string> mapOfAllObj = new Map<string,string>();

            for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
    
                String name = objTyp.getDescribe().getLocalName();
                String label = objTyp.getDescribe().getLabel();
                mapOfAllObj.put(name,label);
            }
            return mapOfAllObj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string saveTrackingObject(string objName){
        try {
            rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c prmntTrckObj = new rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c();
            prmntTrckObj.Name = objName;
            insert prmntTrckObj;
            return 'Setting Updated Successfully!';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}