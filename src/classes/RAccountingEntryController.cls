global class RAccountingEntryController {
    public RAccountingEntryController(){
        
    }
    @RemoteAction
    global static Map<String,Object> start() {
        Map<String,Object> resultMap = new Map<String,Object>();
        List<Transaction__c> lstTransaction = [SELECT Id,Description__c FROM Transaction__c];
        List<Member__c> lstMembers = [SELECT Id,MemberName__c FROM Member__c];
        List<AccountableCode__c> lstAccountableCodes = [SELECT Id,Description__c,Member__c FROM AccountableCode__c];
        resultMap.put('lstTransaction',lstTransaction);
        resultMap.put('lstAccountableCodes',lstAccountableCodes);
        resultMap.put('lstMembers',lstMembers);
        resultMap.put('valueDate',Date.today().format());        
        return resultMap;
    }
    @RemoteAction
    global static void save(String userSelectedEntryJSON){
        System.debug('Received Entry: '+userSelectedEntryJSON);
        Map<String,Object> userSelectedEntry =(Map<String,Object>)JSON.deserializeUntyped(userSelectedEntryJSON);
        Accounting_Entry__c entry = saveEntry(userSelectedEntry);
        countEntry(entry);
        
        List<Contact> contacts = [SELECT Email FROM Contact WHERE Notify_Transaction__c=true];
        if(contacts.size()!=0){
            String[]toAddresses= new String[contacts.size()];
            Integer i = 0;
            for(Contact contact:contacts){
                toAddresses[i]=contact.Email;
                i++;
            }
            Accounting_Entry__c entryAux =[SELECT Name FROM Accounting_Entry__c WHERE Id =:entry.Id];
            
            REntryDetailsController redc = new REntryDetailsController(true);
            redc.fillHeader(entryAux.Name);
            String subject = 'New entry posted! '+ redc.getTransactionName();
            List<REntryDetailsController.Ordinal> ordinals=redc.externalDetails(entryAux.Name);
            String body='';
            
            body+=entryAux.Name+' '+redc.getTransactionName()+'\n\n';
            body+='Value Date: ' +redc.getValueDate() +'\t';
            body+='Created By: ' +redc.getCreatedBy() +'\n';
            body+='Text: ' +(redc.getText()==null?'':redc.getText())+'\n\n';
            
            body+='\tConcept\t\t\tMember\t\t\tDebt\t\tCredit\n';
            for(REntryDetailsController.Ordinal ord:ordinals){
                body+=ord.ordinal+'\t'+ord.accName+'\t\t\t'+ord.member+'\t\t\t'+
                    ord.debt+'\t\t'+ord.credit+'\n';
            }
            
            try{
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
                mail.setToAddresses(toAddresses);        
                mail.setSubject(subject);
                mail.setPlainTextBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }catch(Exception e){
                System.debug('Error during sending mail, limit exceeded: '+e.getMessage());
            }
        }
        return;
    }
    public static void countEntry(Accounting_Entry__c entry){
        Id entryId = entry.Id;
        for(Accounting_Entry_Details__c ordinal:[SELECT Id,Accountable_Code__c,Amount__c,Coin__c,Debt__c,Member__c FROM Accounting_Entry_Details__c WHERE Accounting_Entry_Parent__c =: entryId]){
            Id accCod = ordinal.Accountable_Code__c;
            String coinM = ordinal.Coin__c;
            Id memberID = ordinal.Member__c;
            List<Balance__c> lstBalance =[SELECT Balance__c,Id FROM Balance__c WHERE
                                          Accountable_Code__c =:accCod  AND
                                          Coin__c =: coinM AND
                                          Member__c =: memberID LIMIT 1];
            if(lstBalance.size()==0){
                Balance__c newBalance = new Balance__c();
                newBalance.Accountable_Code__c=ordinal.Accountable_Code__c;
                newBalance.Coin__c=ordinal.Coin__c;
                newBalance.Member__c=ordinal.Member__c;
                newBalance.Balance__c=ordinal.Debt__c?ordinal.Amount__c*(-1):ordinal.Amount__c;
                insert newBalance;
            }
            else{
                Balance__c existingBalance = lstBalance.get(0);
                existingBalance.Balance__c=ordinal.Debt__c?(existingBalance.Balance__c-ordinal.Amount__c):(existingBalance.Balance__c+ordinal.Amount__c);
                    update existingBalance;
            }
        }
        entry.State__c = 'Posted';
        update entry;
    }
    public static Accounting_Entry__c saveEntry(Map<String,Object>userSelectedEntry){
        Accounting_Entry__c entry = new Accounting_Entry__c(); 
        entry.State__c = 'Unposted';
        entry.Transaction__c = Id.valueOf((String)userSelectedEntry.get('transaction'));
        entry.Value_Date__c = Date.parse((String)userSelectedEntry.get('valueDate'));
        entry.Entry_Text__c = (String)userSelectedEntry.get('entryText');
        insert entry;
        
        List<Object>jsonOrdinals = (List<Object>)userSelectedEntry.get('ordinals');
        List<Accounting_Entry_Details__c>ordinals = new List<Accounting_Entry_Details__c>();
        for(Object jsonOrdinal:jsonOrdinals){
            Map<String,Object>mapJsonOrdinal = (Map<String,Object>)jsonOrdinal;
            Accounting_Entry_Details__c ordinal = new Accounting_Entry_Details__c();
            ordinal.Accounting_Entry_Parent__c = entry.Id;
            ordinal.Accountable_Code__c = Id.valueOf((String)mapJsonOrdinal.get('accCode'));
            ordinal.Amount__c = (Decimal)mapJsonOrdinal.get('ammount');
            ordinal.Coin__c = (String)mapJsonOrdinal.get('coin');
            ordinal.Debt__c = (Boolean)mapJsonOrdinal.get('debt');
            
            String strIdMember = (String)mapJsonOrdinal.get('member');
            if(strIdMember.compareTo('')!=0){
                ordinal.Member__c = Id.valueOf(strIdMember);
            }
            ordinal.Ordinal__c = (Decimal)mapJsonOrdinal.get('ordinal');
            ordinal.Ordinal_Text__c = (String)mapJsonOrdinal.get('text');
            ordinals.add(ordinal);
        }
        insert ordinals;
        return entry; 
    }
}