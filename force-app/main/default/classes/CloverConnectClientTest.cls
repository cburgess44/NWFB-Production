@IsTest
global class CloverConnectClientTest {    

    public static final String CREATE_UPDATE_REQ;
    public static final String CREATE_UPDATE_RESP;
    public static final String DELETE_RESP;
    public static final String GET_RESP;
    public static final String AUTH_REQ;
    public static final String ACC_ID;
    public static final String PROFILE_ID;
    public static final String MERCH_ID;

    static {
        CREATE_UPDATE_REQ  = [SELECT Body FROM StaticResource WHERE Name = 'ProfileCreateUpdate' LIMIT 1].Body.toString();
        CREATE_UPDATE_RESP = [SELECT Body FROM StaticResource WHERE Name = 'ProfileCreateUpdateRes' LIMIT 1].Body.toString();
        DELETE_RESP        = [SELECT Body FROM StaticResource WHERE Name = 'ProfileDeleteRes' LIMIT 1].Body.toString();
        GET_RESP           = [SELECT Body FROM StaticResource WHERE Name = 'ProfileGetRes' LIMIT 1].Body.toString();
        AUTH_REQ           = [SELECT Body FROM StaticResource WHERE Name = 'ProfileAuth' LIMIT 1].Body.toString();
        ACC_ID             = '1';
        PROFILE_ID         = '12305454023615201322';
        MERCH_ID           = '496400000840';
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;
        private String reqBody;
        private String resBody;

        public MockHttpResponseGenerator(Boolean isSuccess, String reqBody, String resBody){
            this.isSuccess = isSuccess;
            this.reqBody = reqBody;
            this.resBody = resBody;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.reqBody);
            res.setStatusCode(this.isSuccess? 200 : 500);

            if (res.getStatusCode() == 200){
                res.setBody(this.resBody);
            } else {
                res.setBody('{"error": "Unexpected error."}');
            }
            return res;
        }
    }

    @IsTest
    public static void checkAuthorize() {

        String reqBody = JSON.serialize(AUTH_REQ);

        Test.startTest();

        CloverConnectClient cloverConnect = new CloverConnectClient();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, reqBody, CREATE_UPDATE_RESP));
        
        Map<String, Object> response = new CloverConnectClient().authorize(reqBody);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false, reqBody, CREATE_UPDATE_RESP));

        Test.stopTest();

        System.debug(response);
    }

    @IsTest
    public static void checkSaveProfile() {
        
        String reqBody = JSON.serialize(CREATE_UPDATE_REQ);

        Test.startTest();

        CloverConnectClient cloverConnect = new CloverConnectClient();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, reqBody, CREATE_UPDATE_RESP));

        Object response = new CloverConnectClient().saveProfile(reqBody);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false, reqBody, CREATE_UPDATE_RESP));

        Object response2 = new CloverConnectClient().saveProfile(reqBody);

        Map<String, Object> responseMap = (Map<String, Object>) (response);

        String country = (String) responseMap.get('country');
        System.assert(country == 'US');

        String name = (String) responseMap.get('name');
        System.assert(name == 'TOM JONES');

        Test.stopTest();        
    }

    @IsTest
    public static void checkGetProfile() {
        
        Test.startTest();

        CloverConnectClient cloverConnect = new CloverConnectClient();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, PROFILE_ID, GET_RESP));

        Object response = new CloverConnectClient().getProfile(PROFILE_ID, MERCH_ID);

        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false, PROFILE_ID, GET_RESP));

        // Object response2 = new CloverConnectClient().getProfile(PROFILE_ID, MERCH_ID);
        System.debug(response);

        Test.stopTest();        
    }

    @IsTest
    public static void checkDeleteProfile() {

        Test.startTest();

        CloverConnectClient cloverConnect = new CloverConnectClient();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, PROFILE_ID, DELETE_RESP));

        Object response = new CloverConnectClient().deleteProfile(PROFILE_ID, ACC_ID, MERCH_ID);

        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, PROFILE_ID, DELETE_RESP));

        // Object response2 = new CloverConnectClient().getProfile(PROFILE_ID, '496400000840');

        Test.stopTest();        
    }
}