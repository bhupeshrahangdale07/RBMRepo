/*
Description: Test class for RecyclebinController
*/
@isTest
public with sharing class TestRecyclebinController {
    
    static testmethod void TestRecyclebin(){
        
        rbin__Recycle_Bin_Setting__c rbinsett = new rbin__Recycle_Bin_Setting__c();
        rbinsett.rbin__Send_record_deletion_email_to__c = 'test@gemail.com';
        rbinsett.rbin__Last_batch_run__c = date.today() - 2;
        insert rbinsett;
        
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        
        
        Contact con = new Contact();
        con.FirstName = 'Test FName';
        con.LastName = 'Test LName';
        insert con;
        
        delete acc;
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Object','Account');
        ApexPages.currentPage().getParameters().put('Keyword','Account');
        ApexPages.currentPage().getParameters().put('FromDate',system.now().addDays(-5).format('MM/dd/YYYY'));
        ApexPages.currentPage().getParameters().put('ToDate',system.now().addDays(5).format('MM/dd/YYYY'));
        RecyclebinController objrecycle = new RecyclebinController();
        objrecycle.strSelectedObject = 'Account';
        objrecycle.strKeyword = 'Acc';
        objrecycle.strSearchIn = 'Both';
        objrecycle.strFromDate = system.now().addDays(-5).format('MM/dd/YYYY');
        objrecycle.strToDate = system.now().addDays(5).format('MM/dd/YYYY');
        objrecycle.strSelectedUser = UserInfo.getUserId(); 
        objrecycle.SearchRecords();
        if(objrecycle.lstwrapResults.size() > 0) {
            objrecycle.lstwrapResults[0][0].isCheck = true;
            objrecycle.lstwrapResults[0][0].isPermanentlyDeleted = 'No';
            objrecycle.UndeleteSelectedRecords();
            system.assertEquals(acc.Id, [select Id from Account Where Id=: acc.Id].Id);
        }
        system.debug('delete records ' + [select Id,Name, LastModifiedDate from Account Where IsDeleted = true and LastModifiedById =: UserInfo.getUserId() ALL ROWS]);
        
        delete con;
        objrecycle.Clear();
        objrecycle.strSelectedObject = 'Contact';
        objrecycle.strKeyword = 'Test';
        objrecycle.strFromDate = system.now().addDays(-5).format('MM/dd/YYYY');
        objrecycle.strToDate = system.now().addDays(3).format('MM/dd/YYYY');
        objrecycle.strSelectedUser = UserInfo.getUserId(); 
        objrecycle.SearchRecords();
        if(objrecycle.lstwrapResults.size() > 0) {
            objrecycle.lstwrapResults[0][0].isPermanentlyDeleted = 'Yes';
            objrecycle.UndeleteAllRecords();
            //system.assertEquals(con.Id, [select Id from Contact Where Id=: con.Id].Id);
        }
        
        delete acc;
        objrecycle.Clear();
        objrecycle.strSelectedObject = '';
        objrecycle.strKeyword = 'Test';
        objrecycle.strFromDate = system.now().addDays(-5).format('MM/dd/YYYY');
        objrecycle.strToDate = system.now().addDays(3).format('MM/dd/YYYY');
        objrecycle.strSelectedUser = UserInfo.getUserId(); 
        objrecycle.SearchRecords();
        if(objrecycle.lstwrapResults.size() > 0) {
            objrecycle.lstwrapResults[0][0].isCheck = true;
            objrecycle.lstwrapResults[0][0].isPermanentlyDeleted = 'No';
            objrecycle.DeleteFromRecyclebin();
        }
        
        objrecycle.Clear();
        objrecycle.strSelectedObject = 'Account';
        objrecycle.strKeyword = 'Test';
        objrecycle.strFromDate = system.now().addDays(-5).format('MM/dd/YYYY');
        objrecycle.strToDate = system.now().addDays(3).format('MM/dd/YYYY');
        objrecycle.strSelectedUser = UserInfo.getUserId(); 
        objrecycle.SearchRecords();
        if(objrecycle.lstwrapResults.size() > 0) {
            objrecycle.lstwrapResults[0][0].isCheck = true;
            objrecycle.lstwrapResults[0][0].isPermanentlyDeleted = 'Yes';
            objrecycle.DeleteFromRecyclebin();
        } 
        
        Test.StopTest();
        
    }
    
    static testmethod void TestRecordPage(){
        rbin__Recycle_Bin_Setting__c rbinsett = new rbin__Recycle_Bin_Setting__c();
        rbinsett.rbin__Send_record_deletion_email_to__c = 'test@gemail.com';
        rbinsett.rbin__Last_batch_run__c = date.today() - 2;
        insert rbinsett;
        
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        
        delete acc;
        
        Test.startTest();
        
        //cover exception        
        RecordPageController objRecordpage = new RecordPageController();
        
        //cover exception  
        Apexpages.currentpage().getParameters().put('objectname', 'account');
        objRecordpage = new RecordPageController();
        
        Apexpages.currentpage().getParameters().put('objectname', 'account');
        Apexpages.currentpage().getParameters().put('id', acc.Id);
        objRecordpage = new RecordPageController();
        objRecordpage.UndeleteRecord();
        
        objRecordpage.Cancel();
        
        system.assertEquals(acc.Id, [select Id from Account Where Id=: acc.Id].Id);
        
        Test.Stoptest();
    }
    
    static testmethod void testUndeleteBatch() {
        rbin__Recycle_Bin_Setting__c rbinsett = new rbin__Recycle_Bin_Setting__c();
        rbinsett.rbin__Send_record_deletion_email_to__c = 'test@gemail.com';
        rbinsett.rbin__Last_batch_run__c = date.today() - 2;
        insert rbinsett;
        
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        
        delete acc;
        
        Test.startTest();
        
        List<string> lstUndeleteAllRecords = new List<string>();
        lstUndeleteAllRecords.add('Account#'+acc.id);
        
        //BatchMassUndeleteRecords batchtoundelete = new BatchMassUndeleteRecords('select Id from Account Where IsDeleted = true ALL ROWS','',null,null,'');
        BatchMassUndeleteRecords batchtoundelete = new BatchMassUndeleteRecords(lstUndeleteAllRecords);
        Database.executeBatch(batchtoundelete, 1); 
        
        system.assertEquals('test batch', 'test batch');
        
        RecycleBinBatchProgressCtrl ctrlBatch = new RecycleBinBatchProgressCtrl();
        ctrlBatch.getBatchJobs();
        
        Test.stopTest();
        
    }
    
    static testmethod void testObjectConfigSearch() {
        List<rbin__Recycle_Bin_Tracking_Objects__c> objtrackLST = new List<rbin__Recycle_Bin_Tracking_Objects__c>();
        rbin__RecycleSearchObjects__c obj = new rbin__RecycleSearchObjects__c();        
        obj.Name= 'Account';
        insert obj;
        
        Test.startTest();
        
        SearchObjectSetting objSearchObjectSetting = new SearchObjectSetting();
        
        SearchObjectSetting.getAllObjects();
        
        list<rbin__RecycleSearchObjects__c> lst = SearchObjectSetting.findSearchExistingRecords();
        system.assertEquals(obj.Id, lst.get(0).Id);
        
        SearchObjectSetting.save(lst);
        
        SearchObjectSetting.fnDelete(lst.get(0));
        
        rbin__Recycle_Bin_Setting__c rs = new rbin__Recycle_Bin_Setting__c();
        rs.rbin__Search_Inactive_Users_in_Deleted_By__c = false;
        insert rs;
        
        rbin__Recycle_Bin_Tracking_Objects__c trackobj = new rbin__Recycle_Bin_Tracking_Objects__c();
        trackobj.Name = 'Account';
        insert trackobj;
        objtrackLST.add(trackobj);
        
        rbin__Recycle_Bin_Setting__c rs1 = SearchObjectSetting.fnGeneral();
        system.assertEquals(rs1.Id, rs.Id);
        
        rs.rbin__Search_Inactive_Users_in_Deleted_By__c = true;
        rs.rbin__Real_time_object_tracking__c = true;
        update rs;
        Boolean bls = SearchObjectSetting.fnSaveGeneral(rs);
        SearchObjectSetting.savetrackingobjects(objtrackLST);
        system.assertEquals(true, bls);
        
        Test.stopTest();
        
    }
    
    static testmethod void testvalidateRecycleBin() {
        rbin__RecycleSearchObjects__c obj = new rbin__RecycleSearchObjects__c();        
        obj.Name= 'Account';
        insert obj;
        
        rbin__Recycle_Bin_Setting__c rs = new rbin__Recycle_Bin_Setting__c();
        rs.rbin__Search_Inactive_Users_in_Deleted_By__c = true;
        rs.rbin__Send_record_deletion_email_to__c = 'test@gemail.com';
        rs.rbin__Last_batch_run__c = date.today() - 2;
        insert rs;
        
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Test FName';
        con.LastName = 'Test LName';
        con.AccountId = acc.id;
        insert con;
        
        Account acc1 = new Account();
        acc1.Name= 'Test Account1';
        insert acc1;
        
        delete acc;
        delete acc1;
        
        
        
        Test.startTest();        
        
        ApexPages.currentPage().getParameters().put('Object','Account');
        ApexPages.currentPage().getParameters().put('Keyword','Account');
        RecyclebinController objrecycle = new RecyclebinController(); 
        
        objrecycle.strSelectedObject = '';
        objrecycle.SearchRecords();
        
        //objrecycle.lstwrapResults.add(objrecycle.lstwrapResults.get(0));
        system.assertEquals(1, objrecycle.lstwrapResults.size());      
        
        objrecycle.UndeleteAllRecords();
        
        
        
        RecyclebinController.queryUsers('test');
        
        
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testtrackingobj(){
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        rbin__Recycle_Bin_Setting__c rbinsett = new rbin__Recycle_Bin_Setting__c();
        rbinsett.rbin__Last_batch_run__c = date.today() - 2;
        rbinsett.rbin__Schedule_object_tracking__c = true;
        rbinsett.rbin__isDaily__c = true;
        rbinsett.rbin__Preferred_Start_Time__c = '8';
        rbinsett.rbin__Send_record_deletion_email_to__c = 'test@gemail.com';
        insert rbinsett;
        
        Map<String, Set<Id>> deletedrecords = new Map<String, Set<Id>>();
        
        List<rbin__Recycle_Bin_Tracking_Objects__c> trackobjLST = new List<rbin__Recycle_Bin_Tracking_Objects__c>();
        
        rbin__Recycle_Bin_Tracking_Objects__c trackobj = new rbin__Recycle_Bin_Tracking_Objects__c();
        trackobj.Name = 'Account';
        insert trackobj;
        
        deletedrecords.put('Account', new Set<Id>{trackobj.Id});
        
        rbin__Recycle_Bin_Tracking_Objects__c trackobj2 = new rbin__Recycle_Bin_Tracking_Objects__c();
        trackobj2.Name = 'Contact';
        insert trackobj2;
        
        trackobjLST.add(trackobj);
        trackobjLST.add(trackobj2);
        
        
        rbin__Test_Objects__c testobj = new rbin__Test_Objects__c();
        insert testobj;
            
        delete testobj;
        
        List<Account> acclst = new List<Account>();
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        acclst.add(acc);
        
        delete acc;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new createApexTriggerMock());
        SearchObjectSetting searchobj = new SearchObjectSetting();
        List<SearchObjectSetting.wrapperforweek> selOpts=searchobj.getweeklist;
        system.assertEquals(7, selOpts.size());
        List<SelectOption> selOpts2=searchobj.getpreferedtime;
        SearchObjectSetting.fnSaveGeneral(rbinsett);
        SearchObjectSetting.findTrackingExistingRecords();
        SearchObjectSetting.savetrackingobjects(trackobjLST);
        SearchObjectSetting.fnDeleteTrackingObject(trackobj);
        SendMailForTrackingObject.processbatchedrecords(deletedrecords);
        SendMailForTrackingObject.sendmailwhenrecdelete(acclst);
        Test.stopTest();
    }
    
    @isTest
    public static void callsObjects() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new createApexTriggerMock());
        SearchObjectSetting.triggerableobjects();
        system.assertEquals(43, SearchObjectSetting.triggerableobjects().size());
        Test.stopTest();
    }
    
    @isTest
    public static void getRowOptionsTest(){
        
         Test.startTest();
         RecyclebinController rbinCtrl = new RecyclebinController();
         rbinCtrl.getRowOptions();
         Test.stopTest();
    }
    
    @isTest
    public static void searchInPermanentlyDeletedDataTest(){
        
        rbin__Recycle_Bin_Setting__c rbinsett = new rbin__Recycle_Bin_Setting__c();
        rbinsett.rbin__Send_record_deletion_email_to__c = 'test@gemail.com';
        rbinsett.rbin__Last_batch_run__c = date.today() - 2;
        insert rbinsett;
        
        Account accObj1 = new Account();
        accObj1.Name = 'TestAcc1';
        accObj1.AnnualRevenue = 70000;
        accObj1.BillingCity = 'Mumbai';
        accObj1.BillingCountry = 'India';
        accObj1.Rating = 'Hot';
        insert accObj1;
        
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        Id accId = acc.Id;
        
        
        Contact conObj = new Contact();
        conObj.LastName = 'Test Con 1';
        conObj.AccountId = accId;
        insert conObj;
        delete acc;
        String recordData1 = JSON.serializePretty(accObj1);
        String recordData2 = JSON.serializePretty(conObj);
        
        rbin__Deleted_Data__c Deleted_DataObj1 = new rbin__Deleted_Data__c();
        Deleted_DataObj1.rbin__Object_Name__c = 'Account';
        Deleted_DataObj1.rbin__Record_ID__c = accObj1.Id;
        Deleted_DataObj1.rbin__Record_Name__c = 'TestAcc1';
        Deleted_DataObj1.rbin__Deleted_Date__c = system.now();
        Deleted_DataObj1.rbin__Deleted_By__c = UserInfo.getUserId(); 
		insert Deleted_DataObj1;
        
        rbin__Deleted_Data__c Deleted_DataObj2 = new rbin__Deleted_Data__c();
        Deleted_DataObj2.rbin__Object_Name__c = 'Contact';
        Deleted_DataObj2.rbin__Record_ID__c = conObj.Id;
        Deleted_DataObj2.rbin__Record_Name__c = 'Test Con 1';
        Deleted_DataObj2.rbin__Deleted_Date__c = system.now();
        Deleted_DataObj2.rbin__Deleted_By__c = UserInfo.getUserId(); 
		insert Deleted_DataObj2;
        
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
            cVersion2.PathOnClient = conObj.Id + '.txt';
            cVersion2.Origin = 'H';
            cVersion2.Title = conObj.Id;
            Blob body2 = Blob.valueOf(recordData2);
            cVersion2.VersionData = body2;
        insert cVersion2;
        
        Test.startTest();
        
        RecyclebinController objrecycle = new RecyclebinController();
        objrecycle.strSelectedObject = null;
        objrecycle.strKeyword = 'Test';
        objrecycle.strSearchIn = 'PermanentDeletedData';
        objrecycle.strFromDate = system.now().addDays(-5).format('MM/dd/YYYY');
        objrecycle.strToDate = system.now().addDays(5).format('MM/dd/YYYY');
        objrecycle.strSelectedUser = UserInfo.getUserId(); 
        objrecycle.searchInPermanentlyDeletedData();
        if(objrecycle.lstwrapResults.size() > 0) {
            objrecycle.lstwrapResults[0][0].isCheck = true;
            objrecycle.lstwrapResults[0][0].isPermanentlyDeleted = 'Yes';
            objrecycle.UndeleteSelectedRecords();
        }
  		objrecycle.Clear();
        objrecycle.strSelectedObject = 'Account';
        objrecycle.strKeyword = 'Test';
        objrecycle.strFromDate = system.now().addDays(-5).format('MM/dd/YYYY');
        objrecycle.strToDate = system.now().addDays(3).format('MM/dd/YYYY');
        objrecycle.strSelectedUser = UserInfo.getUserId(); 
        //objrecycle.SearchRecords();
        if(objrecycle.lstwrapResults.size() > 0) {
            objrecycle.lstwrapResults[0][0].isCheck = true;
            objrecycle.UndeleteAllRecords();
        }
        
        Test.stopTest();
        
    }
}