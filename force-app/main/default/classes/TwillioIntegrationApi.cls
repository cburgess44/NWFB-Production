public class TwillioIntegrationApi {

    public String phNumber { get; set; }
    public String smsBody { get; set; }
    public String locationName { get; set; }

    final String vancouverLocationPhoneNumber;
    final String tacomaLocationPhoneNumber;

    errorResponseWrapper erw;

    public TwillioIntegrationApi(String locationName, String phNumber, String body){
        this.phNumber = phNumber;
        this.locationName = locationName;
        // Numbers from Twilio
        this.vancouverLocationPhoneNumber = '3607879356';
        this.tacomaLocationPhoneNumber = '2536500591';
        this.smsBody = body;
    }

    public void sendSMS() {
        HttpRequest req = new HttpRequest();
        String currentPhoneNumberLocation = locationName == 'Tacoma'
                ? this.tacomaLocationPhoneNumber
                : this.vancouverLocationPhoneNumber;

        req.setEndpoint('callout:TwillioSMS');
        req.setMethod('POST');
        req.setBody(
                'To='
                + EncodingUtil.urlEncode(phNumber, 'UTF-8')
                + '&From='
                + EncodingUtil.urlEncode(currentPhoneNumberLocation, 'UTF-8')
                + '&Body='
                + smsBody
        );

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            System.debug('SMS Sent Successfully');
        } else {
            erw = (errorResponseWrapper) JSON.deserialize(res.getBody(), errorResponseWrapper.class);
            System.debug('Error message ' + erw.message);
        }
    }

    public class errorResponseWrapper {

        String code;

        String message;

        String moreInfo;

        String status;

    }
}