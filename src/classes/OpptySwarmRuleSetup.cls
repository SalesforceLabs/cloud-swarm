/*
Copyright (c) 2010 salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

By: Chris Kemp <ckemp@salesforce.com> and Sandy Jones <sajones@salesforce.com>
        with contributions from John Kucera <jkucera@salesforce.com> and
        Reid Carlberg <reid.carlberg@salesforce.com>
*/

public with sharing class OpptySwarmRuleSetup {

    String step1 = null;
    String amount = null;
    String withStage = null;
    String withType = null;
    String[] usersSelected = new String[]{};
    Boolean notify = false;

    public String getStep1() {
        return step1 ;
    }
                    
    public void setStep1(String step1 ) { 
        this.step1 = step1; 
    }

    public String getAmount() {
        return amount;
    }
                    
    public void setAmount(String amount) { 
        this.amount = amount; 
    }

     public String getWithStage() {
        return withStage;
    }
                    
    public void setWithStage(String withStage) { 
        this.withStage = withStage; 
    }

    public List<SelectOption> getStageOptions() {
        List<SelectOption> options = new List<SelectOption>();

        for( OpportunityStage stage: [select MasterLabel from OpportunityStage where IsActive = true order by SortOrder]) {
            options.add(new SelectOption(stage.MasterLabel, stage.MasterLabel));
        }
       return options;
    }

    public String getWithType() {
        return withType;
    }
                    
    public void setWithType(String withType) { 
        this.withType = withType; 
    }

    public List<SelectOption> getTypeOptions() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Opportunity.Type.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
       return options;
    }

    public PaginatedSelectList getUserOptions() {
        PaginatedSelectList options = new PaginatedSelectList ();

        for (User thisUser: 
                [select Id, FirstName, LastName from User where isActive = true and UserType = 'Standard' order by LastName, FirstName]) {
            options.add(new SelectOption(thisUser.Id, thisUser.LastName + ', ' + thisUser.FirstName));
        }
        
        return options;
    }

    public String[] getUsersSelected() {
        return usersSelected;
    }
                    
    public void setUsersSelected(String[] usersSelected) { 
        this.usersSelected = usersSelected; 
    }

    public Boolean getNotify() {
        return notify;
    }
                    
    public void setNotify(Boolean notify) { 
        this.notify = notify; 
    }

    public PageReference saveOpptySwarmRule() {

        // Error checking
        if (step1.equals('Only Opportunities above a certain amount')) {
            try {
                Decimal.valueOf(amount);
            } catch (System.TypeException e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Amount must be a numeric value.');
                ApexPages.addMessage(myMsg);
                return ApexPages.currentPage();
            }
        }

        OpptySwarmRuleSetup.addRules(this.getUsersSelected(), this.step1, this.amount, this.withStage, this.withType, this.notify);
            
        PageReference pageRef = Page.SwarmRuleSaveSuccess;
        pageRef.setRedirect(true);
        return pageRef;
    }

    @future
    public static void addRules(String[] usersSelected, String step1, String amount, String withStage, String withType, Boolean notify) {
    
        List<Opportunity_Swarm_Rule__c> newRules = new List<Opportunity_Swarm_Rule__c>();

        for (String userId: usersSelected) {
    
            String ruleName = step1;
    
            Opportunity_Swarm_Rule__c rule = new Opportunity_Swarm_Rule__c();
            rule.Type__c = step1 ;
            if (step1.equals('Only Opportunities above a certain amount')) {
                rule.Opportunity_Amount__c = Decimal.valueOf(amount);  // already checked for Exception
                ruleName = 'Only Opportunities above $' + amount;
            } else if (step1.equals('Only Opportunities that reach a certain stage in the sales process')) {
                rule.Opportunity_Stage__c = withStage;
                ruleName = 'Only Opportunities that reach the Stage: ' + withStage;
            } else if (step1.equals('Only Opportunities of a certain Type')) {
                rule.Opportunity_Type__c = withType;
                ruleName = 'Only Opportunities of Type: ' + withType;
            }
            
            rule.User__c = userId;
            rule.Description__c = ruleName;
            rule.Notify_on_Swarm__c = notify;
            newRules.add(rule);
        }    
    
        insert newRules;
    }
}