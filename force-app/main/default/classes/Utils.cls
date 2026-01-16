/**
 * Created by Gustavo on 17/02/23.
 */

public without sharing class Utils {

    public static Map<Id, SObject> listToMap(String field, List<SObject> records) {
        Map<Id, SObject> newMap = new Map<Id, SObject>();

        for (SObject o : records) {
            Object value = getSObjectValue(o, field);

            if (value != null) {
                newMap.put((Id) value, o);
            }
        }

        return newMap;
    }

    public static Map<String, SObject> listToStringMap(SObjectField field, List<SObject> records) {
        Map<String, SObject> newMap = new Map<String, SObject>();

        for (SObject o : records) {
            if (o.get(field) != null)
                newMap.put((String) o.get(field), o);
        }

        return newMap;
    }

    /**
     * Method created to get relationship values i.e CustomObject__r.ACustomObject__r.BCustomField__c
     * @param source SObject
     * @param fieldName String
     *
     * @return the value itself typed as Object
     */
    public static Object getSObjectValue(SObject source, String fieldName) {
        Object value = null;
        List<String> fields = new List<String>(fieldName.split('[.]'));

        if (fields.size() == 1) {
            return source.get(fieldName);
        } else {
            List<SObject> objects = new List<SObject>{
                    source
            };
            Integer lastPos = fields.size();

            for (Integer i = 0; i < lastPos; i++) {
                if (i == lastPos - 1) {

                    try {
                        value = objects[i].get(fields[i]);
                    } catch (Exception e) {
                        value = null;
                    }

                } else {
                    objects.add(objects[i].getSObject(fields[i].trim()));
                }
            }
        }

        return value;
    }

    /**
     * Convert a list to a Map according to the field passed as param
     * @return Map<Id, List<Object>>
     * @field String (i.e: 'Name' or even relationships field 'Contact.Name'
     * @record List<SObject> records
     */
    public static Map<String, List<SObject>> listToMapLists(String field, List<SObject> records) {
        Map<String, List<SObject>> newMap = new Map<String, List<SObject>>();

        for (SObject o : records) {
            Object value = getSObjectValue(o, field);
            if (value != null) {
                List<SObject> listObjects = newMap.get((Id) value);

                if (listObjects == null) {
                    newMap.put((String) value, new List<SObject>{
                            o
                    });
                } else {
                    listObjects.add(o);
                }
            }
        }

        return newMap;
    }

    public static ContentVersion createContentVersion(String name, Blob body, Id parentId) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = name;
        contentVersion.Title = name;
        contentVersion.VersionData = body;

        insert contentVersion;

        if (parentId != null) {
            Id documentId = [
                    SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :contentVersion.Id
            ].ContentDocumentId;
            createContentDocumentLink(documentId, parentId);
        }

        return contentVersion;
    }

    public static ContentDocumentLink createContentDocumentLink(Id documentId, Id parentId) {
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = documentId;
        contentDocumentLink.LinkedEntityId = parentId;
        contentDocumentLink.ShareType = 'V'; // Inferred permission
        contentDocumentLink.Visibility = 'AllUsers';

        insert contentDocumentLink;

        return contentDocumentLink;
    }

    public static Id getRecordTypeId(SObjectType type, String name) {
        Id rtId = null;
        try {
            rtId = type
                    .getDescribe()
                    .getRecordTypeInfosByName()
                    .get(name)
                    .getRecordTypeId();
        } catch (System.NullPointerException e) {
        }

        return rtId;
    }
}