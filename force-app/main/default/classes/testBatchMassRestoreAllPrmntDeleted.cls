@isTest
public class testBatchMassRestoreAllPrmntDeleted {
    
    @testSetup static void testDataSetup() {
        Account objAcc1 = new Account();
        objAcc1.Name = 'TestAcc12';
        objAcc1.AnnualRevenue = 150000;
        objAcc1.BillingCity = 'Thane';
        objAcc1.BillingCountry = 'India';
        insert objAcc1;
        
        Account objAcc2 = new Account();
        objAcc2.Name = 'TestAcc134';
        objAcc2.AnnualRevenue = 150000;
        objAcc2.BillingCity = 'Thane';
        objAcc2.BillingCountry = 'India';
        insert objAcc2;
        
        String recordData1 = JSON.serializePretty(objAcc1);
        String recordData2 = JSON.serializePretty(objAcc2);

       rbin__Deleted_Data__c Deleted_DataObj1 = new rbin__Deleted_Data__c();
        Deleted_DataObj1.rbin__Object_Name__c = 'Account';
        Deleted_DataObj1.rbin__Record_ID__c = objAcc1.Id;
        Deleted_DataObj1.rbin__Record_Name__c = 'TestAcc12';
        Deleted_DataObj1.rbin__Deleted_Date__c = system.now();
		insert Deleted_DataObj1;
        
        rbin__Deleted_Data__c Deleted_DataObj2 = new rbin__Deleted_Data__c();
        Deleted_DataObj2.rbin__Object_Name__c = 'Account';
        Deleted_DataObj2.rbin__Record_ID__c = objAcc2.Id;
        Deleted_DataObj2.rbin__Record_Name__c = 'TestAcc123';
        Deleted_DataObj2.rbin__Deleted_Date__c = system.now();
		insert Deleted_DataObj2;
        
         ContentVersion cVersion1 = new ContentVersion();
            cVersion1.ContentLocation = 'S';
            cVersion1.PathOnClient = objAcc1.Id + '.txt';
            cVersion1.Origin = 'H';
            cVersion1.Title = objAcc1.Id;
            Blob body1 = Blob.valueOf(recordData1);
            cVersion1.VersionData = body1;
        insert cVersion1;
        
        ContentVersion cVersion2 = new ContentVersion();
            cVersion2.ContentLocation = 'S';
            cVersion2.PathOnClient = objAcc2.Id + '.txt';
            cVersion2.Origin = 'H';
            cVersion2.Title = objAcc2.Id;
            Blob body2 = Blob.valueOf(recordData2);
            cVersion2.VersionData = body2;
        insert cVersion2;
    }
    @isTest
    public static void BatchMassRestoreAllPrmntDeletedTest(){
        
        List<String> lstRecIds = new List<String>();
        for (rbin__Deleted_Data__c rec : [Select Id, rbin__Record_ID__c, rbin__Object_Name__c FROM rbin__Deleted_Data__c]) {
            lstRecIds.add(rec.rbin__Record_ID__c);
        }
        Test.startTest();
        BatchMassRestoreAllPrmntDeleted bt = new BatchMassRestoreAllPrmntDeleted(lstRecIds);
        database.executeBatch(bt);
        Test.stopTest();
    }
}