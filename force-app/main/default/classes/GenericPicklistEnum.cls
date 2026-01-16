/**
 * Created by dudunato on 2019-03-20.
 */

public with sharing class GenericPicklistEnum extends PicklistEnum {

    private static GenericPicklistEnum INSTANCE;

    private GenericPicklistEnum(SObjectField field) {
        super(field);
    }

    private static void getInstance(SObjectField field) {
        if (INSTANCE == null) INSTANCE = new GenericPicklistEnum(field);
    }

    public static Entry valueOf(String value, SObjectField field) {
        getInstance(field);
        return INSTANCE.getEntry(value);
    }

    public static Entry[] values(SObjectField field) {
        getInstance(field);
        return INSTANCE.getEntries();
    }



}