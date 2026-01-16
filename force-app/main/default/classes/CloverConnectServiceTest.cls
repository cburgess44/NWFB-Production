@IsTest
public with sharing class CloverConnectServiceTest {

    @IsTest
    static void testExecuteAuthorizeMethod() {

        // CloverConnectService CloverConnectServiceInst = new CloverConnectService();
        CloverConnectSettingsSelector.mock = (CloverConnectSettingsSelector) Test.createStub(CloverConnectSettingsSelector.class, new Mocks.CloverConnectSettingsSelectorMock());
        CloverConnectLogManager.mock       = (CloverConnectLogManager) Test.createStub(CloverConnectLogManager.class, new Mocks.CloverConnectLogManagerMock());
        CloverConnectService.mock          = (CloverConnectService) Test.createStub(CloverConnectService.class, new Mocks.CloverConnectServiceMock());

        CloverConnectService service = CloverConnectService.getInstance();
        service.authorize(null,null);
    }
    
    @IsTest
    static void testExecuteError() {

        CloverConnectService CloverConnectServiceInst = new CloverConnectService();        
        CloverConnectServiceInst.authorize(null,null);
    }
}