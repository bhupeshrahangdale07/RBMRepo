/*
// --------------------------------------------------------------------------------------------------------------

// This class used to delete Error log recordswhich are created 10 days before and this batch will run everyday.
// It will dlete those records which are created 10 days before.
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         06-12-2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/
public class batchDeleteErrorLogs Implements Database.Batchable<sobject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String queryString = 'SELECT Id, Name FROM rbin__Error_Log__c WHERE CreatedDate < LAST_N_DAYS :10';
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc,List<rbin__Error_Log__c> lstErrorLogs) {
        //Delete 15 days old Error logs 
        Database.delete(lstErrorLogs, false);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
}