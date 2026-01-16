/**
 * Created by dudunato on 01/02/22.
 */

public with sharing class SObjectDeepCloneController {

    @AuraEnabled
    public static Id fullClone(Id recordId, List<String> childrenRelationships, Map<String, Object> fieldsValue) {

        if (fieldsValue != null && !fieldsValue.isEmpty()) {
            return new SObjectDeepClone(
                    recordId,
                    new Set<String>(childrenRelationships),
                    fieldsValue
            ).save();
        }

        return new SObjectDeepClone(recordId, new Set<String>(childrenRelationships)).save();
    }

}