public with sharing class Mocks {
    
    public class CloverConnectServiceMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'authorize') {
                return null;
            }

            return null;
        }
    }

    public class CloverConnectLogManagerMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'setCurrentService') {
                return 'Authorize';
            }
            
            if (stubbedMethodName == 'queueUp') {
                return null;
            }
            
            return null;
        }
    }
    
    public class CloverConnectSettingsSelectorMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

           
            return null;
        }
    }

    public class CloverConnectClientMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

           if (stubbedMethodName == 'authorize') {
                return (Map<String, Object>) JSON.deserializeUntyped('"{\n  \"country\": \"US\",\n  \"address\": \"123 MAIN STREET\",\n  \"resptext\": \"Profile Saved\",\n  \"city\": \"ANYTOWN\",\n  \"acctid\": \"1\",\n  \"respcode\": \"09\",\n  \"defaultacct\": \"Y\",\n  \"accttype\": \"VISA\",\n  \"token\": \"9441149619831111\",\n  \"respproc\": \"PPS\",\n  \"phone\": \"7778789999\",\n  \"profileid\": \"12305454023615201322\",\n  \"name\": \"TOM JONES\",\n  \"auoptout\": \"N\",\n  \"postal\": \"19090\",\n  \"expiry\": \"0214\",\n  \"region\": \"AK\",\n  \"respstat\": \"A\"\n}"');
           }

            return null;
        }
    }
  
    public class CloverConnectPaymentManagerMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

           if (stubbedMethodName == 'callHandlers') {
                return null;
           }

            return null;
        }
    }    
}