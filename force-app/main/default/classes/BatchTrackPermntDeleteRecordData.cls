public class BatchTrackPermntDeleteRecordData Implements Database.Batchable<sobject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('Select Id, Name From rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c');
    }
    
    public void execute(Database.BatchableContext bc,List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> objList){
        
        
        
        set<string> objNames=new set<string>();
        for(rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c cs:objList){
            system.debug('Name-'+cs.Name);
            objNames.add(cs.Name); 
            string objName=cs.Name;
            SObjectType sObjType = ((SObject) Type.forName(objName).newInstance())
                .getSObjectType();
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(objName);
            Sobject genericObject = convertType.newSObject();
            
            DescribeSObjectResult describeResult = genericObject.getSObjectType().getDescribe();
            
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
            //system.debug('Fields Names-'+fieldNames);
            String myQuery =
                ' SELECT ' +
                String.join( fieldNames, ',' ) +
                ' FROM ' +
                describeResult.getName()+' Where IsDeleted=true ALL ROWS'
                ;
            system.debug('myQuery'+myQuery);
            List<SObject> records = Database.query( myQuery );
            
            System.debug( records );
            
        }
        /*for(string objct:objNames){
String strQuery ='Select FIELDS(STANDARD) From '+objct+' Where IsDeleted=true ALL ROWS';  
System.debug('Query-'+strQuery);
List<sObject> QueryResultList= Database.query(strQuery);
system.debug('Result-'+ QueryResultList);
system.debug('Name---'+QueryResultList[0]);
//store into a list and apply for loop
for(sObject lst:QueryResultList){
system.debug('Record Name-'+lst);
}
}*/
        
    }
    public void finish(Database.BatchableContext bc){
        
    }
}