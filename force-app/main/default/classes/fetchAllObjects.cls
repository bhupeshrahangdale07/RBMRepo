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
    public static string saveTrackingObject(List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> objNameList){
        try {
            List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> prmntObjectTrackingList = new List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>();
            
            for(rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c objName : objNameList){

                rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c prmntTrckObj = new rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c();

                prmntTrckObj.Name = objName.Name;
                system.debug('Name'+objName.Name);

                prmntObjectTrackingList.add(prmntTrckObj);
                
            }
            insert prmntObjectTrackingList;

            return 'Setting Updated Successfully!';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled (cacheable = true)
    public static List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> fetchAllRecords(){
        try {
            list<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> lst = new list<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>([select id,name from rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c order by Name]);
            return lst;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string deleteObject(String removeObjectIds){
        try {
            List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> deleteObjectRecordList = new List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>();
            system.debug('Id List-'+removeObjectIds);
           // if(String.isNotBlank(removeObjectIds)){
            // List<Id> objectIds = removeObjectIds.split(',');
            deleteObjectRecordList = [SELECT Id FROM rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c WHERE Id =: removeObjectIds];
            system.debug('Delete record list-'+deleteObjectRecordList);
       // }
        delete deleteObjectRecordList;
        return 'Record Deleted Successfully!';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}