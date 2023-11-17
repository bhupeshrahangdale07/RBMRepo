@isTest
public class testUtilityCls {

    @testSetup static void dataSetupTest(){
        
         Account accObj1 = new Account();
        accObj1.Name = 'TestAcc1';
        accObj1.AnnualRevenue = 70000;
        accObj1.BillingCity = 'Mumbai';
        accObj1.BillingCountry = 'India';
        accObj1.Rating = 'Hot';
        insert accObj1;
        
        Account accObj2 = new Account();
        accObj2.Name = 'TestAcc2';
        accObj2.AnnualRevenue = 50000;
        accObj2.BillingCity = 'Pune';
        accObj2.BillingCountry = 'India';
        accObj2.Rating = 'Cold';
        insert accObj2;
        
        Contact conObj1 = new Contact();
        conObj1.FirstName = 'Con1';
        conObj1.AccountId = accObj2.Id;
        conObj1.LastName = 'Test';
        conObj1.Email = 'test@gmail.com';
        insert conObj1;

        String recordData1 = JSON.serializePretty(accObj1);
        String recordData2 = JSON.serializePretty(accObj2);
        String recordData3 = JSON.serializePretty(conObj1);

       rbin__Deleted_Data__c Deleted_DataObj1 = new rbin__Deleted_Data__c();
        Deleted_DataObj1.rbin__Object_Name__c = 'Account';
        Deleted_DataObj1.rbin__Record_ID__c = accObj1.Id;
        Deleted_DataObj1.rbin__Record_Name__c = 'TestAcc1';
        Deleted_DataObj1.rbin__Deleted_Date__c = system.now();
        insert Deleted_DataObj1;
        
        rbin__Deleted_Data__c Deleted_DataObj2 = new rbin__Deleted_Data__c();
        Deleted_DataObj2.rbin__Object_Name__c = 'Account';
        Deleted_DataObj2.rbin__Record_ID__c = accObj2.Id;
        Deleted_DataObj2.rbin__Record_Name__c = 'TestAcc2';
        Deleted_DataObj2.rbin__Deleted_Date__c = system.now();
        insert Deleted_DataObj2;
        
        rbin__Deleted_Data__c Deleted_DataObj3 = new rbin__Deleted_Data__c();
        Deleted_DataObj3.rbin__Object_Name__c = 'Contact';
        Deleted_DataObj3.rbin__Record_ID__c = conObj1.Id;
        Deleted_DataObj3.rbin__Record_Name__c = 'Con1 Test';
        Deleted_DataObj3.rbin__Deleted_Date__c = system.now();
        insert Deleted_DataObj3;
        
        ContentVersion cVersion1 = new ContentVersion();
            cVersion1.ContentLocation = 'S';
            cVersion1.PathOnClient = accObj1.Id + '.txt';
            cVersion1.Origin = 'H';
            cVersion1.Title = accObj1.Id;
            Blob body1 = Blob.valueOf(recordData1);
            cVersion1.VersionData = body1;
        insert cVersion1;
        
        ContentVersion cVersion2 = new ContentVersion();
            cVersion2.ContentLocation = 'S';
            cVersion2.PathOnClient = accObj2.Id + '.txt';
            cVersion2.Origin = 'H';
            cVersion2.Title = accObj2.Id;
            Blob body2 = Blob.valueOf(recordData2);
            cVersion2.VersionData = body2;
        insert cVersion2;
        
        ContentVersion cVersion3 = new ContentVersion();
            cVersion3.ContentLocation = 'S';
            cVersion3.PathOnClient = conObj1.Id + '.txt';
            cVersion3.Origin = 'H';
            cVersion3.Title = conObj1.Id;
            Blob body3 = Blob.valueOf(recordData3);
            cVersion3.VersionData = body3;
        insert cVersion3;
    }
    
    @isTest
    public static void sObjectsToRestoreTest(){
        
        Set<String> recIds = new Set<String>();
        for (rbin__Deleted_Data__c rec : [Select Id, rbin__Record_ID__c, rbin__Object_Name__c FROM rbin__Deleted_Data__c]) {
            recIds.add(rec.rbin__Record_ID__c);
        }
        
        Test.startTest();
        List<Sobject> lstSobjects = UtilityCls.sObjectsToRestore(recIds);
        Test.stopTest();
        System.assertEquals(false, lstSobjects.isEmpty(), 'Success');
    }
    
    @isTest
     public static void fetchObjectFieldMapTest(){
        String sObjectName = 'Account';
        Test.startTest();
        Map<String, Schema.SObjectField> fieldMap = UtilityCls.fetchObjectFieldMap(sObjectName);
        UtilityCls.fetchObjectKeyFields();
        Test.stopTest();
        System.assertEquals(false, fieldMap.keySet().isEmpty(), 'Success');
    }
    
    @isTest
     public static void createFileAttachmentTest(){
        
         Map<String, String> mapDeletedData = new Map<String, String>();
         Set<String> setRecIds = new Set<String>();
         for (Account acc : [Select Id, Name, AnnualRevenue, BillingCity, BillingCountry, Rating, CreatedDate, LastModifiedDate FROM Account]) {
             mapDeletedData.put(acc.Id, JSON.serializePretty(acc));
             setRecIds.add(acc.Id);
         }
         
        Test.startTest();
        UtilityCls.createFileAttachment(mapDeletedData, setRecIds);
        Test.stopTest();
    }
}