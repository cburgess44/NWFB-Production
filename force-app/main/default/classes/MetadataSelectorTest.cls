/**
 * Created by Gustavo on 08/01/24.
 */

@IsTest
private class MetadataSelectorTest {

    @IsTest
    static void getAgreementText() {
        MetadataSelector.getInstance();
        System.assert(MetadataSelector.getAgreementText() != null);
    }
}