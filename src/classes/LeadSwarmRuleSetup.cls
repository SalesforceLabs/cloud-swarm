/*
Copyright (c) 2011 salesforce.com, inc.
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

public with sharing class LeadSwarmRuleSetup {

    String step1 = null;
    String withRating = null;
    String withStatus = null;
    String withSource = null;
    String withIndustry = null;
    String[] usersSelected = new String[]{};
    Boolean notify = false;

    public String getStep1() {
        return step1 ;
    }
                    
    public void setStep1(String step1 ) { 
        this.step1 = step1; 
    }

    public String getWithRating() {
        return withRating;
    }
                    
    public void setWithRating(String withRating) { 
        this.withRating = withRating; 
    }

    public List<SelectOption> getRatingOptions() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Lead.Rating.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
       return options;
    }

    public String getWithStatus() {
        return withStatus;
    }
                    
    public void setWithStatus(String withStatus) { 
        this.withStatus = withStatus; 
    }

    public List<SelectOption> getStatusOptions() {
        List<SelectOption> options = new List<SelectOption>();

        for(LeadStatus leadStatus: [select MasterLabel from LeadStatus order by SortOrder]) {
            options.add(new SelectOption(leadStatus.MasterLabel, leadStatus.MasterLabel));
        }
       return options;
    }

    public String getWithSource() {
        return withSource;
    }
                    
    public void setWithSource(String withSource) { 
        this.withSource = withSource; 
    }

    public List<SelectOption> getSourceOptions() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Lead.LeadSource.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
       return options;
    }

    public String getWithIndustry() {
        return withIndustry;
    }
                    
    public void setWithIndustry(String withIndustry) { 
        this.withIndustry = withIndustry; 
    }

    public List<SelectOption> getIndustryOptions() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Lead.Industry.getDescribe();
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

    public PageReference saveLeadSwarmRule() {

        LeadSwarmRuleSetup.addRules(this.getUsersSelected(), this.step1, this.withRating, this.withStatus, 
            this.withSource, this.withIndustry,  this.notify);
            
        PageReference pageRef = Page.SwarmRuleSaveSuccess;
        pageRef.setRedirect(true);
        return pageRef;
    }

    @future
    public static void addRules(String[] usersSelected, String step1, String withRating, String withStatus, 
        String withSource, String withIndustry, Boolean notify) {
    
        List<Lead_Swarm_Rule__c> newRules = new List<Lead_Swarm_Rule__c>();

        for (String userId: usersSelected) {
    
            String ruleName = step1;
    
            Lead_Swarm_Rule__c rule = new Lead_Swarm_Rule__c();
            rule.Type__c = step1 ;
            if (step1.equals('Only Leads with a certain Rating')) {
                rule.Rating__c = withRating;
                ruleName = 'Only Leads with Rating: ' + withRating;
            } else if (step1.equals('Only Leads with a certain Status')) {
                rule.Status__c = withStatus;
                ruleName = 'Only Leads with Status: ' + withStatus;
            } else if (step1.equals('Only Leads from a certain Lead Source')) {
                rule.Lead_Source__c = withSource;
                ruleName = 'Only Leadsfrom Lead Source: ' + withSource;
            } else if (step1.equals('Only Leads for a certain Industry')) {
                rule.Industry__c = withIndustry;
                ruleName = 'Only Leads with Industry: ' + withIndustry;
            }
            
            rule.User__c = userId;
            rule.Description__c = ruleName;
            rule.Notify_on_Swarm__c = notify;
            newRules.add(rule);
        }    
    
        insert newRules;
    }
}