public without sharing class ServiceItemDao extends GenericDao {

    @TestVisible
    private static ServiceItemDao mock;

    public ServiceItemDao() {
    }

    private ServiceItemDao(List<SObject> requests, Map<Id, SObject> oldRequestsById) {
        super(requests, oldRequestsById);
    }
    private ServiceItemDao(List<SObject> requests) {
        super(requests);
    }

    public static ServiceItemDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new ServiceItemDao(new List<ServiceItem__c>());
        }
    }

    public override void beforeInsert() {
        setFees();
        //setItemCost();
    }

    public override void beforeUpdate() {
        //setItemCost();
    }

    public override void afterInsert() {
        rollup();
    }

    public override void afterUpdate() {
        rollup();
    }

    private void rollup() {
        if (this.records != null && !this.records.isEmpty()) {
            Database.update(dlrs.RollupService.rollup(this.records));
        }
    }
    @TestVisible
    private void setFees() {
        Set<Id> serviceItemIds = new Set<Id>();
        Set<Id> servicesIds = new Set<Id>();

        for (ServiceItem__c serviceItem : (List<ServiceItem__c>) this.records) {
            serviceItemIds.add(serviceItem.Product__c);
            servicesIds.add(serviceItem.Service__c);
        }

        Map<Id, Product__c> productMap = ProductSelector.getInstance().getMapProductById(serviceItemIds);
        Map<Id, Service__c> servicesMap = ServiceSelector.getInstance().getServicesRecordTypesById(servicesIds);

        if (productMap.isEmpty()) return;

        for (ServiceItem__c serviceItem : (List<ServiceItem__c>) this.records) {
            Product__c productServiceItem = productMap.get(serviceItem.Product__c);
            Service__c service = servicesMap.get(serviceItem.Service__c);
            System.debug('service.RecordType.DeveloperName => ' + service.RecordType.DeveloperName);
            System.debug('serviceItem.TotalItemPrice__c => ' + serviceItem.TotalItemPrice__c);
            serviceItem.Estimated_Value__c = productServiceItem.Estimated_Value__c;

            if(!serviceItem.Override_Product_Fee__c){
                if ((service.RecordType.DeveloperName == 'ClientRequest' || service.RecordType.DeveloperName == 'GeneralDelivery')
                        && serviceItem.TotalItemPrice__c == 0.00) {
                    serviceItem.TotalItemPrice__c = productServiceItem.Product_Fee__c;
                } else if ((service.RecordType.DeveloperName == 'DonationPickup' || service.RecordType.DeveloperName == 'GeneralPickup')
                        &&  serviceItem.TotalItemPrice__c == 0.00) {
                    serviceItem.TotalItemPrice__c = productServiceItem.Pick_up_Fee__c;
                }
            }

            serviceItem.TaxableItem__c = productServiceItem.Taxable__c;
        }
    }

//    private void setItemCost() {
//        Set<Id> serviceItemIds = new Set<Id>();
//        for (ServiceItem__c serviceItem : (List<ServiceItem__c>) this.records) {
//            serviceItemIds.add(serviceItem.Id);
//        }
//
//        Map<String, ServiceFeesSettings__mdt> serviceFeesSettingsByDevName = new Map<String, ServiceFeesSettings__mdt>();
//        List<ServiceFeesSettings__mdt> serviceFeesSettings = CustomMetadataSelector.getInstance().getMdtByStatus();
//        for (ServiceFeesSettings__mdt serviceFeeSetting : serviceFeesSettings) {
//            serviceFeesSettingsByDevName.put(serviceFeeSetting.DeveloperName, serviceFeeSetting);
//        }
//
//        List<ServiceItem__c> servicesItems = ServiceItemSelector.getInstance().getRequestItemByIds(serviceItemIds);
//
//        for (ServiceItem__c serviceItem : servicesItems) {
//            if (serviceItem.Service__c == null ) continue;
//            if (serviceItem.Service__r.RecordType.DeveloperName != 'GeneralDelivery') continue;
//            //serviceItem.ItemCost__c = serviceFeesSettingsByDevName.get('GeneralDeliveryServiceItemFee').FeeAmount__c;
//        }
//    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new ServiceItemDao(objects, oldObjectsById);
        }
    }
}