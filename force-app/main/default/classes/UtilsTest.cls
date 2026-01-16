/**
 * Created by Eric Solari on 04/01/2024.
 */
@IsTest
public with sharing class UtilsTest {

    @IsTest

    public static void testlistToMap(){
        Account acc = createAccount();
        insert acc;
        List<SObject> accountList = new List<SObject>{acc};
        Utils.listToMap('Id',accountList);
    }

    @IsTest
    public static void testlistToStringMap(){
        Account acc = createAccount();
        insert acc;
        List<SObject> accountList = new List<SObject>{acc};
        Utils.listToStringMap(Account.Name,accountList);
    }

    @IsTest
    public static void testlistToMapLists(){
        Account acc = createAccount();
        insert acc;
        List<SObject> accountList = new List<SObject>{acc};
        Utils.listToMapLists('Id',accountList);
    }

    @IsTest
    public static void testcreateContentVersion(){
        Account acc = createAccount();
        insert acc;
        Blob b = Blob.valueOf('testString');

        Utils.createContentVersion('Name',b,acc.Id);
    }

    private static Account createAccount() {
        return new Account(
                Name = 'Test Account',
                Type = 'Agency',
                Active__c = true
        );
    }
}