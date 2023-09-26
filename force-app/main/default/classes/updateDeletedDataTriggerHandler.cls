public class updateDeletedDataTriggerHandler {
    
    public static void updateFields(List<rbin__Deleted_Data__c> recordList){
        List<rbin__Deleted_Data__c> lstRecordsToUpdate=new List<rbin__Deleted_Data__c>();
        TimeZone tz = UserInfo.getTimeZone();
        DateTime dt = Datetime.now();
        DateTime currentDt=dt.addSeconds((tz.getOffset(dt)/1000));
        
        for(rbin__Deleted_Data__c rec:recordList){
            rbin__Deleted_Data__c recObj=new rbin__Deleted_Data__c();
            recObj.Id=rec.Id;
            recObj.rbin__Restored_Record_Id__c=rec.Id;
            recObj.rbin__Has_Restored__c=true;
            recObj.rbin__Restored_Date_Time__c=currentDt;
            lstRecordsToUpdate.add(recObj);
        }
        Update lstRecordsToUpdate;
    }
}