List<Service__c> toUpdate = [
    SELECT Id, Name 
    FROM Service__c 
    WHERE Id IN ('a0ePC00000TnMi1YAB','a0ePC00000TnPBBYA3','a0ePC00000TnVgHYAV',
                 'a0ePC00000TnD8HYAV','a0ePC00000TmYIBYA3','a0ePC00000Tk3dOYAR',
                 'a0ePC00000TjcRsYAJ','a0ePC00000TiDQgYAN','a0ePC00000TiH4TYAV',
                 'a0ePC00000ThbdAYAR')
];

for (Service__c s : toUpdate) {
    s.Name = s.Name.replace('2026', '2025');
}

update toUpdate;
System.debug('Updated ' + toUpdate.size() + ' records');
