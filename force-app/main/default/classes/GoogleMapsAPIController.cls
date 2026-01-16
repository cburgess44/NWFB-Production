/**
 * Created by Gustavo on 10/11/23.
 */

public with sharing class GoogleMapsAPIController {
    @AuraEnabled
    public static String buildGetDirectionsURL(List<Stop__c> stops, String destination) {
        GoogleMapsApiSetting__mdt mapsSettings = [
                SELECT
                        Url__c,
                        Key__c
                FROM GoogleMapsApiSetting__mdt
                LIMIT 1
        ];

        String stopsAddress = '';

        for (Stop__c stop : stops){
            stopsAddress += String.isNotBlank(stop.Address__c) ? '|' + stop.Address__c : '';
        }

        String encodedStopsAddress = EncodingUtil.urlEncode(stopsAddress, 'UTF-8');
        String googleMapsKey = mapsSettings.Key__c;
        String googleMapsBaseUrl = mapsSettings.Url__c;

        return (
                googleMapsBaseUrl +
                '/json?origin=' +
                EncodingUtil.urlEncode(destination,'UTF-8') +
                '&destination=' +
                EncodingUtil.urlEncode(destination,'UTF-8') +
                '&waypoints=optimize:true' +
                encodedStopsAddress +
                '&key=' +
                googleMapsKey
        );
    }

    @AuraEnabled
    public static String getMapDirections(List<Stop__c> stops, String destination) {
        String directionsUrl = buildGetDirectionsURL(stops, destination);
        return MapsAPICallout.callMapDirections(directionsUrl);
    }

    @AuraEnabled
    public static String getIframeMapsUrl(String originUrl, List<Stop__c> stops, String destination, Boolean optimize) {
        String stopsAddress = '';
        Long timestamp = Datetime.now().getTime();

        if (stops == null || stops.isEmpty()) {
            return null;
        }

        for (Stop__c stop : stops) {
            if (stop.Service__c == null) continue;

            String serviceRecordType = stop.Service__r.RecordType.DeveloperName;
            String serviceSubType = stop.Service__r.SubType__c;
            String stopColor = '';

            if (serviceRecordType == 'ClientRequest') {
                stopColor = 'red';
            } else if (serviceRecordType == 'DonationPickup' || serviceRecordType == 'GeneralPickup') {
                stopColor = 'blue';
            } else if (serviceRecordType == 'GeneralDelivery' && serviceSubType == 'Hope Del.') {
                stopColor = 'purple';
            } else if (serviceRecordType == 'GeneralDelivery' && serviceSubType != 'Hope Del.') {
                stopColor = 'orange';
            }

            String pointerTitle = 'Stop: ' + stop.StopOrder__c + ' Name: ' + stop.Customer__r.Name;
            stopsAddress += String.isNotBlank(stop.Address__c)
                    ? '|' + stop.Address__c + '/' + stopColor + '/' + pointerTitle
                    : '';
        }

        String encodedStopsAddress = EncodingUtil.urlEncode(stopsAddress, 'UTF-8');

        return (
                originUrl +
                '/apex/googleMapsApi?t=' +
                timestamp +
                '&startpoint=' +
                EncodingUtil.urlEncode(destination, 'UTF-8') +
                '&endpoint=' +
                EncodingUtil.urlEncode(destination, 'UTF-8') +
                '&waypoints=' +
                encodedStopsAddress +
                '&optimize=' +
                optimize
        );
    }
}