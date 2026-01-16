public without sharing class TripService {
    public TripService() {

    }

    public static Boolean buildStopsTrip(Id tripId){
        Trip__c trip = TripSelector.getInstance().getTripById(tripId)[0];
        GoogleMapsIntegrationApi gmia = new GoogleMapsIntegrationApi();
        //verify the origin, destinatio, stops. if one of them doesnt exist, then don't calculate.
        if(trip.Stops__r == null || trip.Stops__r.size() == 0) return false;
        //Map<String, Object> routes = gmia.getRoute(trip.Origin__r.PhysicalAddress__c, trip.Destination__r.PhysicalAddress__c, trip.Stops__r);
        Map<String, Object> routes = gmia.getRoute(trip.Location__r.Address__c, trip.Stops__r);
        List<Object> indexOrderList = (List<Object>) routes.get('waypoint_order');
        List<Object> stopsList = (List<Object>) routes.get('legs');

        for (Integer i = 0; i < indexOrderList.size(); i++){
            //set Stop Order
//            trip.Stops__r.get(i).StopOrder__c = Integer.valueOf(indexOrderList.indexOf(i)) + 1;
            //set travel time
            trip.Stops__r.get(i).TravelTime__c = Math.ceil(Double.valueOf(((Map<String, Object>) ((Map<String, Object>) stopsList.get(indexOrderList.indexOf(i))).get('duration')).get('value'))/60);
        }
        Database.update(trip.Stops__r,true);
        return true;
    }


    public Boolean buildStopsTripsSet(Set<Id> tripsIdSet){
        List<Trip__c> trips = TripSelector.getInstance().getTripByIdSet(tripsIdSet);
        List<Stop__c> stopsToUpdate = new List<Stop__c>();
        GoogleMapsIntegrationApi googleMapsIntegrationApi = new GoogleMapsIntegrationApi();

        for (Trip__c trip : trips) {
            if(trip.Stops__r == null || trip.Stops__r.size() == 0) continue;
            List<Stop__c> stopByTrip = trip.Stops__r;

            Map<String, Object> routes = googleMapsIntegrationApi.getRoute(
                    trip.Location__r.Address__c,
                    trip.Stops__r
            );

            List<Object> indexOrderList = (List<Object>) routes.get('waypoint_order');
            List<Object> stopsList = (List<Object>) routes.get('legs');

            Decimal durationTimeMinutes = calculateTotalTime((List<Object>) routes.get('legs'));
            String durationTimeMinutesString = parseTripDurationToString(durationTimeMinutes);

            trip.GoogleRouteTime__c = durationTimeMinutes;
            trip.CalculatedTotalTimeText__c = durationTimeMinutesString;

            for (Integer i = 0; i < (indexOrderList != null ? indexOrderList.size() : 0); i++) {
//                stopByTrip[i].StopOrder__c = Integer.valueOf(indexOrderList.indexOf(i)) + 1;
                stopByTrip[i].TravelTime__c = Math.floor(Double.valueOf(((Map<String, Object>)
                        ((Map<String, Object>) stopsList.get(indexOrderList.indexOf(i))).get('duration')).get('value')) / 60
                );
            }

            stopsToUpdate.addAll(stopByTrip);
        }

        TriggerManagement.disableTrigger('StopTrigger');
        TriggerManagement.disableTrigger('TripTrigger');

        Database.update(stopsToUpdate,false);
        Database.update(trips,false);

        TriggerManagement.enableTrigger('TripTrigger');
        TriggerManagement.enableTrigger('StopTrigger');

        return true;
    }

    private static Decimal calculateTotalTime(List<Object> googleSteps) {
        Decimal totalTimeMinutes = 0;

        if (googleSteps == null || googleSteps.isEmpty()) return 0;

        for (Integer i = 0; i < (googleSteps != null ? googleSteps.size() : 0); i++) {
            Map<String, Object> currentStep = (Map<String, Object>) googleSteps[i];
            Map<String, Object> currentStepDuration = (Map<String, Object>) currentStep.get('duration');
            totalTimeMinutes += Math.floor(Double.valueOf(currentStepDuration.get('value')) / 60);
        }

       return totalTimeMinutes;
    }

    private static String parseTripDurationToString(Decimal durationTimeMinutes) {
        Decimal hours = Math.floor(durationTimeMinutes / 60);
        Decimal minutes = (Decimal) Math.mod((Long) durationTimeMinutes, (Long) 60);
        return hours != 0 ? hours + 'h,  min' + minutes : minutes + 'min';
    }
}