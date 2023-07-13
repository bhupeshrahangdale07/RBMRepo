public class gettriggerableobjects {
    
    public static List<String> demo(){
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<Schema.DescribeSObjectResult> standardObjDescs = new List<Schema.DescribeSObjectResult>();
        for (Schema.SObjectType sobj : gd.values()) {
            Schema.DescribeSObjectResult sobjDesc = sobj.getDescribe();
            if (!sobjDesc.isCustom()) {
                standardObjDescs.add(sobjDesc);
            }
        }
        
        List<String> triggerableList = new List<String>();
        List<String> NOTtriggerableList = new List<String>();
        for (Schema.DescribeSObjectResult schemaDesc : standardObjDescs) {
            String sobjStruct = JSON.serialize(schemaDesc);
            DescribeSobjectResultJSON sobjProps = (DescribeSobjectResultJSON)JSON.deserialize(sobjStruct, DescribeSobjectResultJSON.class);
            if (sobjProps.triggerable) {
                triggerableList.add(sobjProps.name);
            } else {
                NOTtriggerableList.add(sobjProps.name);
            }
        }
        triggerableList.sort();
        for (String notTrigble : triggerableList) {
            System.debug(notTrigble);
        }
        system.debug(triggerableList.size());
        return triggerableList;
    }
    
    public class DescribeSobjectResultJSON { 
            public String name {get;set;}
            public Boolean triggerable {get;set;}
        }
    
}