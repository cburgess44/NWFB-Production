/**
 * Created by Eric Solari on 03/01/2024.
 */
@IsTest
public with sharing class AuthorizationUtilTest {

    @IsTest
    public static void testMethods() {
        Account acc = new Account(Name = 'test');
        insert acc;
        AuthorizationUtil.isCreateable(acc.Id.getSobjectType());
        AuthorizationUtil.isUpdateable(acc.Id.getSobjectType());
        AuthorizationUtil.isAccessible(acc.Id.getSobjectType());
        AuthorizationUtil.isUpsertable(acc.Id.getSobjectType());
        AuthorizationUtil.isDeletable(acc.Id.getSobjectType());
        AuthorizationUtil.isUndeletable(acc.Id.getSobjectType());
        AuthorizationUtil.isMergeable(acc.Id.getSobjectType());
        AuthorizationUtil.assertAccessible(acc.Id.getSobjectType());
        AuthorizationUtil.assertCreateable(acc.Id.getSobjectType());
        AuthorizationUtil.assertUpdateable(acc.Id.getSobjectType());
        AuthorizationUtil.assertUpsertable(acc.Id.getSobjectType());
        AuthorizationUtil.assertDeletable(acc.Id.getSobjectType());
        AuthorizationUtil.assertUndeletable(acc.Id.getSobjectType());
        AuthorizationUtil.assertMergeable(acc.Id.getSobjectType());
    }
}