public class GoogleMapsIntegrationQueuable implements Queueable, Database.AllowsCallouts {

    public Set<Id> tripsIdSet;

    public GoogleMapsIntegrationQueuable(Set<Id> tripsIdSet) {
        this.tripsIdSet = tripsIdSet;
    }

    public void startQueueable(){
        new TripService().buildStopsTripsSet(this.tripsIdSet);
    }

    public void execute(QueueableContext context) {
        startQueueable();
    }
}