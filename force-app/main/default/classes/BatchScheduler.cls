/**
 * Created by Gustavo on 12/03/24.
 */

global class BatchScheduler implements Schedulable {
    global String batchClassName { get; set; }
    global Database.Batchable<SObject> batchClass { get; set; }

    global Integer batchSize { get; set; } {
        batchSize = 200;
    }

    global void execute(SchedulableContext context) {

        if (batchClassName != null) {
            Database.executeBatch((Database.Batchable<SObject>) Type.forName(batchClassName).newInstance(), batchSize);
        } else if (batchClass != null) {
            Database.executeBatch(batchClass, batchSize);
        }

    }

}