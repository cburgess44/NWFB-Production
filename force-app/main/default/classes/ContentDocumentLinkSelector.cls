/**
 * Created by Gustavo on 15/05/24.
 */

public with sharing class ContentDocumentLinkSelector {
    private static ContentDocumentLinkSelector instance = null;

    public static ContentDocumentLinkSelector getInstance() {
        if (instance == null) {
            instance = new ContentDocumentLinkSelector();
        }
        return instance;
    }

    public List<ContentDocumentLink> getByLinkedEntityId(Set<Id> linkedEntityIds) {
        return [
                SELECT
                        Id,
                        ContentDocumentId,
                        LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :linkedEntityIds
                ORDER BY ContentDocument.CreatedDate ASC
        ];
    }
}