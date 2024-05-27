//added by Kandisa Technologies to set default value in custom setting after installed RecycleBin app 
global class RecyclePostInstalledClass implements InstallHandler {
	global void onInstall(InstallContext context) {

		List<rbin__RecycleSearchObjects__c> lst = new List<rbin__RecycleSearchObjects__c>([select Id,Name from rbin__RecycleSearchObjects__c where id != null]);

		if(lst.size() == 0){
			rbin__RecycleSearchObjects__c  objsearch = new rbin__RecycleSearchObjects__c();
            if(Schema.sObjectType.rbin__RecycleSearchObjects__c.fields.Name.isCreateable()){ 
             	objsearch.Name = 'Account';   
            }
			lst.add(objsearch);

			objsearch = new rbin__RecycleSearchObjects__c();
            if(Schema.sObjectType.rbin__RecycleSearchObjects__c.fields.Name.isCreateable()){
				objsearch.Name = 'Contact';
            }
			lst.add(objsearch);

			objsearch = new rbin__RecycleSearchObjects__c();
            if(Schema.sObjectType.rbin__RecycleSearchObjects__c.fields.Name.isCreateable()){
				objsearch.Name = 'Lead';
            }
			lst.add(objsearch);

			insert lst;
		}
		

		List<rbin__Recycle_Bin_Setting__c> lstsettings = new List<rbin__Recycle_Bin_Setting__c>([select Id,rbin__Record_Limits__c,rbin__Search_Inactive_Users_in_Deleted_By__c,rbin__Show_Default_Entries__c from rbin__Recycle_Bin_Setting__c]);

		if(lstsettings.size() == 0){
			rbin__Recycle_Bin_Setting__c  objsetting = new rbin__Recycle_Bin_Setting__c();
            if(Schema.sObjectType.rbin__Recycle_Bin_Setting__c.fields.rbin__Record_Limits__c.isCreateable()){
				objsetting.rbin__Record_Limits__c = 3500;
            }
            if(Schema.sObjectType.rbin__Recycle_Bin_Setting__c.fields.rbin__Show_Default_Entries__c.isCreateable()){
				objsetting.rbin__Show_Default_Entries__c = 10;
            }
            if(Schema.sObjectType.rbin__Recycle_Bin_Setting__c.fields.rbin__Search_Inactive_Users_in_Deleted_By__c.isCreateable()){
				objsetting.rbin__Search_Inactive_Users_in_Deleted_By__c = true;
            }
			insert objsetting;
		}

		System.schedule('Get Permanent Deleted Data Batch', '0 0 01 * * ? *' , new createPermanentDeletedRecordBatch(1));
		System.schedule('Delete Error logs batch', '0 0 01 * * ? *' , new batchDeleteErrorLogs());
	}
}