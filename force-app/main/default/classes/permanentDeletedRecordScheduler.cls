// This is scheduler class to call createPermanentDeletedRecordBatch
// This is scheudled every day at once.
public class permanentDeletedRecordScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        createPermanentDeletedRecordBatch batchClass = new createPermanentDeletedRecordBatch();
        Database.executeBatch(batchClass); 
    }
}