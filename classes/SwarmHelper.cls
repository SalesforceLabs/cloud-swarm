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

public with sharing global class SwarmHelper {
    
    @future
    public static void evaluateOpptyRules(List<Id> opptyIds) {
    
        List<Opportunity> opptys = [SELECT Id, Name, Type, AccountId, StageName, Amount, OwnerId
            FROM Opportunity WHERE Id IN :opptyIds];
        
        List<Opportunity_Swarm_Rule__c> rules = [select type__c, Opportunity_amount__c, Opportunity_stage__c, 
                    Opportunity_type__c, user__c, ownerId, Notify_on_Swarm__c from Opportunity_Swarm_Rule__c WHERE user__r.IsActive = true];
        List<EntitySubscription> subs = new List<EntitySubscription>();
        
        // Get all subscriptions and put in string concatenating subscriber + object ID
        List<EntitySubscription> existingOpptySubs = [select SubscriberId, ParentId from EntitySubscription where ParentId in :opptys];
        Set<String> existingOpptySubsIds = new Set<String>();
        for (EntitySubscription es:existingOpptySubs) {
            existingOpptySubsIds.add((String)es.SubscriberId + es.ParentId);
        }//for
        
        // Pre-load list of all account owners for opptys
        Set<Id> acctIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity o : opptys) {
            if (acctIds.contains(o.AccountId) == FALSE){
                acctIds.add(o.AccountId);
            }//if
            ownerIds.add(o.OwnerId);
        }//for
    
        List<Account> accts = [SELECT ownerId, Id FROM Account WHERE Id IN :acctIds];
        Map<Id,Id> acctOwnerIds = new Map<Id, Id>();
        for (Account a : accts) {
            acctOwnerIds.put(a.Id, a.ownerId);
        }//for
        
        // Pre-load list of managers for oppty owners
        Map<Id,Id> ownerManagers = new Map<Id, Id>();
        for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds]) {
            if (u.ManagerId != null) {
                ownerManagers.put(u.Id, u.ManagerId);
            }//if
        }//for

        List<FeedPost> feedNotifications = new List<FeedPost>();
        
        for (Opportunity thisOppty : opptys) {
        
            for (Opportunity_Swarm_Rule__c rule : rules) {
    
                if (rule.Type__c.equals('All Opportunities') ||
                    (rule.Type__c.equals('Only Opportunities for Accounts I Own') && thisOppty.AccountId != null &&
                        rule.User__c == acctOwnerIds.get(thisOppty.AccountId)) ||
                    (rule.Type__c.equals('Only Opportunities owned by my direct reports')
                        && rule.User__c == ownerManagers.get(thisOppty.OwnerId)) ||
                    (rule.Type__c.equals('Only Opportunities above a certain amount') && 
                        rule.Opportunity_Amount__c <= (thisOppty.Amount)) ||
                    (rule.Type__c.equals('Only Opportunities that reach a certain stage in the sales process') && 
                        rule.Opportunity_Stage__c.equals(thisOppty.StageName)) ||
                    (rule.Type__c.equals('Only Opportunities of a certain Type') && 
                        rule.Opportunity_Type__c.equals(thisOppty.Type))                
                    ) {
                    
                    if (existingOpptySubsIds.contains((string)rule.User__c + thisOppty.Id) == FALSE){
                        subs.add(new EntitySubscription(parentId = thisOppty.id, SubscriberId = rule.User__c));
                        existingOpptySubsIds.add((String)rule.User__c + thisOppty.id);
                        
                        // Add swarming notification to user's feed
                        if (rule.Notify_on_Swarm__c == true) {
                            FeedPost swarmNotification = new FeedPost();
                            swarmNotification.Type = 'LinkPost';
                            swarmNotification.ParentId = rule.User__c;
                            swarmNotification.Title = thisOppty.Name;
                            swarmNotification.Body = 'You have automatically swarmed an Opportunity.';
                            swarmNotification.LinkUrl = '/' + thisOppty.Id;
                            feedNotifications.add(swarmNotification);
                        }// if 3
                    }//if 2
                }//if 1
            }//for 2  rules
        }//for 1 oppty's

        try {
            insert subs;
            insert feedNotifications;
        } catch (DMLException e) {
            system.debug('Oppty Swarm subscriptions were not all inserted successfully.  Error: '+e);
        }//catch
    }//evaluateOpptyRules


    @future
    public static void evaluateCaseRules(List<Id> caseIds) {
    
        // Get user and group key prefixes so we can test to see what the UserOrGroupId field contains
        List<Case> cases = [SELECT Id, AccountId, CaseNumber, Status, Priority, Type, OwnerId FROM Case WHERE Id IN :caseIds];
        List<Case_Swarm_Rule__c> rules = [SELECT type__c, case_status__c, case_priority__c, case_type__c, 
            user__c, ownerId, Notify_on_Swarm__c FROM Case_Swarm_Rule__c WHERE user__r.IsActive = true];
        
        // Get all subscriptions and put in string concatenating subscriber + object ID
        List<EntitySubscription> subs = new List<EntitySubscription>();
        List<EntitySubscription> existingOpptySubs = [select SubscriberId, ParentId from EntitySubscription where ParentId in :cases];
        Set<String> existingOpptySubsIds = new Set<String>();
        for (EntitySubscription es : existingOpptySubs){
            existingOpptySubsIds.add((String)es.SubscriberId + es.ParentId);
        }//for
        
        // Pre-load list of all account owners for cases
        Set<Id> acctIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : cases) {
            if (acctIds.contains(c.AccountId) == FALSE){
                acctIds.add(c.AccountId);
            }//if
            ownerIds.add(c.OwnerId);
        }//for
    
        List<Account> accts = [SELECT ownerId, Id FROM Account WHERE Id IN :acctIds];
        Map<Id,Id> acctOwnerIds = new Map<Id, Id>();
        for (Account a: accts){
            acctOwnerIds.put(a.Id, a.ownerId);
        }//for

        // Pre-load list of managers for case owners
        Map<Id,Id> ownerManagers = new Map<Id, Id>();
        for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds]) {
            if (u.ManagerId != null) {
                ownerManagers.put(u.Id, u.ManagerId);
            }//if
        }//for

        List<FeedPost> feedNotifications = new List<FeedPost>();

        for (Case thisCase : cases) {
            for (Case_Swarm_Rule__c rule : rules) {
    
                if (rule.Type__c.equals('All Cases') ||
                    (rule.Type__c.equals('Only Cases for Accounts I Own') && thisCase.AccountId != null &&
                        rule.User__c == acctOwnerIds.get(thisCase.AccountId)) ||
                    (rule.Type__c.equals('Only Cases owned by my direct reports')
                        && rule.User__c == ownerManagers.get(thisCase.OwnerId)) ||
                    (rule.Type__c.equals('Only Cases with a certain Status') && 
                        rule.Case_Status__c.equals(thisCase.Status)) ||
                    (rule.Type__c.equals('Only Cases with a certain Priority') && 
                        rule.Case_Priority__c.equals(thisCase.Priority)) ||
                    (rule.Type__c.equals('Only Cases of a certain Type') && 
                        rule.Case_Type__c.equals(thisCase.Type))                
                    ) {
                    if (existingOpptySubsIds.contains((string)rule.User__c + thisCase.Id) == FALSE){
                        subs.add(new EntitySubscription(parentId = thisCase.id, SubscriberId = rule.User__c));
                        existingOpptySubsIds.add((string)rule.User__c + thisCase.Id);

                        // Add swarming notification to user's feed
                        if (rule.Notify_on_Swarm__c == true) {
                            FeedPost swarmNotification = new FeedPost();
                            swarmNotification.Type = 'LinkPost';
                            swarmNotification.ParentId = rule.User__c;
                            swarmNotification.Title = thisCase.CaseNumber;
                            swarmNotification.Body = 'You have automatically swarmed a Case.';
                            swarmNotification.LinkUrl = '/' + thisCase.Id;
                            feedNotifications.add(swarmNotification);
                        }// if 3
                    }//if 2
                }//if 1
            }//for 2
        }//for 1
        
        try {
            insert subs;
            insert feedNotifications;
        } catch (DMLException e) {
            system.debug('Case Swarm subscriptions were not all inserted successfully.  Error: ' + e);
        }//catch
    }//evaluateCaseRules
    

    @future
    public static void evaluateLeadRules(List<Id> leadIds) {
    
        List<Lead> leads = [SELECT Id, Name, Rating, Status, LeadSource, Industry, OwnerId FROM Lead WHERE Id IN :leadIds];
        
        List<Lead_Swarm_Rule__c> rules = [SELECT Type__c, Rating__c, Status__c, Lead_Source__c, Industry__c, 
                    User__c, OwnerId, Notify_on_Swarm__c from Lead_Swarm_Rule__c WHERE user__r.IsActive = true];
        List<EntitySubscription> subs = new List<EntitySubscription>();
        
        // Get all subscriptions and put in string concatenating subscriber + object ID
        List<EntitySubscription> existingLeadSubs = [select SubscriberId, ParentId from EntitySubscription where ParentId in :leads];
        Set<String> existingLeadSubsIds = new Set<String>();
        for (EntitySubscription es : existingLeadSubs) {
            existingLeadSubsIds.add((String)es.SubscriberId + es.ParentId);
        }//for

        // Pre-load list of managers for lead owners
        Set<Id> ownerIds = new Set<Id>();
        for (Lead l : leads) {
            ownerIds.add(l.OwnerId);
        }//for

        Map<Id,Id> ownerManagers = new Map<Id, Id>();
        for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds]) {
            if (u.ManagerId != null) {
                ownerManagers.put(u.Id, u.ManagerId);
            }//if
        }//for
        
        List<FeedPost> feedNotifications = new List<FeedPost>();
        
        for (Lead thisLead : leads) {
        
            for (Lead_Swarm_Rule__c rule: rules) {
    
                if (rule.Type__c.equals('All Leads') ||
                    (rule.Type__c.equals('Only Leads owned by my direct reports')
                        && rule.User__c == ownerManagers.get(thisLead.OwnerId)) ||
                    (rule.Type__c.equals('Only Leads with a certain Rating') && 
                        rule.Rating__c.equals(thisLead.Rating)) ||
                    (rule.Type__c.equals('Only Leads with a certain Status') && 
                        rule.Status__c <= (thisLead.Status)) ||
                    (rule.Type__c.equals('Only Leads from a certain Lead Source') && 
                        rule.Lead_Source__c.equals(thisLead.LeadSource)) ||
                    (rule.Type__c.equals('Only Leads for a certain Industry') && 
                        rule.Industry__c.equals(thisLead.Industry))                
                    ) {
                    
                    if (existingLeadSubsIds.contains((string)rule.User__c + thisLead.Id) == FALSE){
                        subs.add(new EntitySubscription(parentId = thisLead.id, SubscriberId = rule.User__c));
                        existingLeadSubsIds.add((String)rule.User__c + thisLead.id);
                        
                        // Add swarming notification to user's feed
                        if (rule.Notify_on_Swarm__c == true) {
                            FeedPost swarmNotification = new FeedPost();
                            swarmNotification.Type = 'LinkPost';
                            swarmNotification.ParentId = rule.User__c;
                            swarmNotification.Title = thisLead.Name;
                            swarmNotification.Body = 'You have automatically swarmed a Lead.';
                            swarmNotification.LinkUrl = '/' + thisLead.Id;
                            feedNotifications.add(swarmNotification);
                        }// if 3
                    }//if 2
                }//if 1
            }//for 2  rules
        }//for 1 oppty's

        try {
            insert subs;
            insert feedNotifications;
        } catch (DMLException e) {
            system.debug('Lead Swarm subscriptions were not all inserted successfully.  Error: '+e);
        }//catch
    }//evaluateOpptyRules
   
}//class