/**
 * Created by dudunato on 2019-03-12.
 */

public virtual without sharing class GenericDao extends AbstractTriggerHandler {

    private static final Logger GENERIC_LOGGER = Logger.getInstance(GenericDao.class);
    
    @TestVisible
    protected List<SObject> records;
    protected Map<Id, SObject> oldRecordsById;

    @TestVisible
    private static GenericDao mock;

    protected GenericDao() {
    }

    protected GenericDao(List<SObject> records) {
        this.records = records;
    }

    protected GenericDao(List<SObject> records, Map<Id, SObject> oldRecordsById) {
        this.records = records;
        this.oldRecordsById = oldRecordsById;
    }

    public static GenericDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new GenericDao();
        }
    }

    public virtual List<SObject> get() {
        return this.records;
    }

    public virtual Map<Id, SObject> getOld() {
        return this.oldRecordsById;
    }

    public virtual void set(List<SObject> records) {
        this.records = records;
    }

    public List<SObject> listSObjects(String objectName, List<String> fields, String filters) {
        String soql = 'SELECT ' + String.join(fields, ',');
        soql += ' FROM ' + objectName;

        if (filters != null && filters != '') {
            soql += ' WHERE Id != NULL ' + filters;
        }

        GENERIC_LOGGER.debug(' Filters: {0}', filters);
        GENERIC_LOGGER.debug(' SOQL Query: {0}', soql);

        return Database.query(soql);
    }

    public List<SObject> saveSObjects(List<SObject> sObjects) {
        List<SObject> toInsert = new List<SObject>();
        List<SObject> toUpdate = new List<SObject>();

        for (SObject sObj : sObjects) {
            if (sObj.Id == null) {
                toInsert.add(sObj);
            } else {
                toUpdate.add(sObj);
            }
        }

        if (CollectionUtil.isNotEmpty(toInsert)) insert toInsert;
        if (CollectionUtil.isNotEmpty(toUpdate)) update toUpdate;

        return sObjects;
    }

    public virtual void save() {
        this.saveSObjects(this.records);
    }

    public List<SObject> deleteSObjects(List<SObject> sObjects) {
        if (CollectionUtil.isNotEmpty(sObjects)) delete sObjects;
        return sObjects;
    }

    public List<SObject> deleteSObjectsByFilter(String objectName, String filters) {
        List<SObject> sObjects = this.listSObjects(objectName, new List<String>{ 'Id' }, filters);
        if (sObjects.isEmpty()) return sObjects;
        return this.deleteSObjects(sObjects);
    }

    public List<PicklistEnum.Entry> getPicklist(String objectName, String fieldName) {
        SObjectField field = Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap()
                .get(fieldName);
        return GenericPicklistEnum.values(field);
    }
}