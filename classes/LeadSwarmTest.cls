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

public class LeadSwarmTest {

    static List<User> testUsers = new List<User>();

    static User user1 = null;
    static User user2 = null;
    
    static void buildUp() {
        user1 = SwarmTestUtility.createTestUser();
        user2 = SwarmTestUtility.createTestUser();
        user2.Manager = user1;
    }   

    static void tearDown() {}

    static testMethod void testGetOptions() {
        LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();

        // Check that options are populating
        System.assert(0 < controller.getRatingOptions().size());
        System.assert(0 < controller.getStatusOptions().size());
        System.assert(0 < controller.getSourceOptions().size());
        System.assert(0 < controller.getIndustryOptions().size());
    }

    static testMethod void testAllLeads() {

        buildUp();

        System.runAs ( user1 ) {

            Test.startTest();
            PageReference pageRef = Page.LeadSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();
    
            controller.setStep1('All Leads');
            System.assertEquals('All Leads', controller.getStep1());
            controller.setUsersSelected(new String[]{LeadSwarmTest.user1.Id, LeadSwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(LeadSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(LeadSwarmTest.user2.Id));
            String nextPage = controller.saveLeadSwarmRule().getUrl();
    
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
    
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Lead_Swarm_Rule__c where CreatedById = :user1.Id]);
        }
        
        tearDown();
    }

    static testMethod void testAllLeads2() {

        buildUp();

        System.runAs ( user1 ) {

            Test.startTest();

            // Create a lead
            Lead testLead = new Lead();
            testLead.LastName = 'Swarm Test Lead';
            testLead.Company = 'Swarm Test Company';
            insert testLead;
            
            // Check that swarm was added -- note that for test resiliance you need to cycle through the group
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :currentUser.Id]);
            }
        }
        
        tearDown();
    }


    static testMethod void testOwnedByDirectReport() {

        buildUp();
        
        System.runAs ( user1 ) {
        
            Test.startTest();
            PageReference pageRef = Page.LeadSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();
    
            System.assert(0 < controller.getRatingOptions().size());
        
            controller.setStep1('Only Leads owned by my direct reports');
            System.assertEquals('Only Leads owned by my direct reports', 
                controller.getStep1());
            controller.setNotify(true);
            System.assertEquals(true, controller.getNotify());
            controller.setUsersSelected(new String[]{LeadSwarmTest.user1.Id, LeadSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(LeadSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(LeadSwarmTest.user2.Id));
            String nextPage = controller.saveLeadSwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Lead_Swarm_Rule__c where CreatedById = :user1.Id]);
        }
        
        tearDown();
    }  

    static testMethod void testOwnedByDirectReport2() {

        buildUp();
        
        System.runAs ( user1 ) {
        
            Test.startTest();

            // Create an Lead with wrong rating (no followers)
            Lead testLead = new Lead();
            testLead.LastName = 'Swarm Test Lead for Manager';
            testLead.Company = 'Swarm Test Company for Manager';
            insert testLead;
        
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :currentUser.Id]);
                }
            }
        }

        System.runAs ( user2 ) {
        
            Lead testLeadSuccess = new Lead();
            testLeadSuccess.LastName = 'Swarm Test Lead for Direct Report';
            testLeadSuccess.Company = 'Swarm Test Company for Direct Report';
            insert testLeadSuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testLeadSuccess.Id and SubscriberId = :currentUser.Id]);
            }  
        }
        
        tearDown();
    }  
    

    static testMethod void testRating() {

        buildUp();
        
        System.runAs ( user1 ) {
        
            Test.startTest();
            PageReference pageRef = Page.LeadSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();
    
            System.assert(0 < controller.getRatingOptions().size());
        
            controller.setStep1('Only Leads with a certain Rating');
            System.assertEquals('Only Leads with a certain Rating', 
                controller.getStep1());
            controller.setWithRating('Hot');
            System.assertEquals('Hot', controller.getWithRating());
            controller.setNotify(true);
            System.assertEquals(true, controller.getNotify());
            controller.setUsersSelected(new String[]{LeadSwarmTest.user1.Id, LeadSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(LeadSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(LeadSwarmTest.user2.Id));
            String nextPage = controller.saveLeadSwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Lead_Swarm_Rule__c where CreatedById = :user1.Id]);
        }
        
        tearDown();
    }  

    static testMethod void testRating2() {

        buildUp();
        
        System.runAs ( user1 ) {
        
            Test.startTest();

            // Create an Lead with wrong rating (no followers)
            Lead testLead = new Lead();
            testLead.LastName = 'Swarm Test Lead with Wrong Rating';
            testLead.Company = 'Swarm Test Company with Wrong Rating';
            testLead.Rating = 'Cold';
            insert testLead;
        
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :currentUser.Id]);
                }
            }
        
            Lead testLeadSuccess = new Lead();
            testLeadSuccess.LastName = 'Swarm Test Lead with Correct Rating';
            testLeadSuccess.Company = 'Swarm Test Company with Correct Rating';
            testLeadSuccess.Rating = 'Hot';
            insert testLeadSuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testLeadSuccess.Id and SubscriberId = :currentUser.Id]);
            }  
        }
        
        tearDown();
    }  


    static testMethod void testStatus() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();
            PageReference pageRef = Page.LeadSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();
    
            System.assert(0 < controller.getStatusOptions().size());
        
            controller.setStep1('Only Leads with a certain Status');
            System.assertEquals('Only Leads with a certain Status', controller.getStep1());
            controller.setWithStatus('Working');
            System.assertEquals('Working', controller.getWithStatus());
            controller.setUsersSelected(new String[]{LeadSwarmTest.user1.Id, LeadSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(LeadSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(LeadSwarmTest.user2.Id));
            String nextPage = controller.saveLeadSwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Lead_Swarm_Rule__c where CreatedById = :user1.Id]);
        }

        tearDown();
    }  

    static testMethod void testStatus2() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();

            // Create an Lead with wrong status (no followers)
            Lead testLead = new Lead();
            testLead.LastName = 'Swarm Test Lead with Wrong Status';
            testLead.Company = 'Swarm Test Company with Wrong Status';
            testLead.Status = 'New';
            insert testLead;
            
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :currentUser.Id]);
                }
            } 
        
            Lead testLeadSuccess = new Lead();
            testLeadSuccess.LastName = 'Swarm Test Lead with Correct Status';
            testLeadSuccess.Company = 'Swarm Test Company with Correct Status';
            testLeadSuccess.Rating = 'Working';
            insert testLeadSuccess ;
            
            // Check that swarm was added -- need at least two subscribers (might have more);
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testLeadSuccess.Id and SubscriberId = :currentUser.Id]);
            }          
        }

        tearDown();
    }  


    static testMethod void testSource() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();
            PageReference pageRef = Page.LeadSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();
    
            System.assert(0 < controller.getSourceOptions().size());
        
            controller.setStep1('Only Leads from a certain Lead Source');
            System.assertEquals('Only Leads from a certain Lead Source', controller.getStep1());
            controller.setWithSource('Partner Referral');
            System.assertEquals('Partner Referral', controller.getWithSource());
            controller.setUsersSelected(new String[]{LeadSwarmTest.user1.Id, LeadSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(LeadSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(LeadSwarmTest.user2.Id));
            String nextPage = controller.saveLeadSwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Lead_Swarm_Rule__c where CreatedById = :user1.Id]);
        }

        tearDown();
    }  

    static testMethod void testSource2() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();

            // Create an Lead from wrong source (no followers)
            Lead testLead = new Lead();
            testLead.LastName = 'Swarm Test Lead with Wrong Source';
            testLead.Company = 'Swarm Test Company with Wrong Source';
            testLead.LeadSource = 'Newspaper';
            insert testLead;
            
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :currentUser.Id]);
                }
            } 
        
            Lead testLeadSuccess = new Lead();
            testLeadSuccess.LastName = 'Swarm Test Lead with Correct Source';
            testLeadSuccess.Company = 'Swarm Test Company with Correct Source';
            testLeadSuccess.LeadSource = 'Partner Referral';
            insert testLeadSuccess ;
            
            // Check that swarm was added -- need at least two subscribers (might have more);
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testLeadSuccess.Id and SubscriberId = :currentUser.Id]);
            }          
        }

        tearDown();
    }  


    static testMethod void testIndustry() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();
            PageReference pageRef = Page.LeadSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            LeadSwarmRuleSetup controller = new LeadSwarmRuleSetup();
    
            System.assert(0 < controller.getIndustryOptions().size());
        
            controller.setStep1('Only Leads for a certain Industry');
            System.assertEquals('Only Leads for a certain Industry', controller.getStep1());
            controller.setWithIndustry('SaaS');
            System.assertEquals('SaaS', controller.getWithIndustry());
            controller.setUsersSelected(new String[]{LeadSwarmTest.user1.Id, LeadSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(LeadSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(LeadSwarmTest.user2.Id));
            String nextPage = controller.saveLeadSwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Lead_Swarm_Rule__c where CreatedById = :user1.Id]);
        }

        tearDown();
    }  

    static testMethod void testIndustry2() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();

            // Create an Lead with wrong industry (no followers)
            Lead testLead = new Lead();
            testLead.LastName = 'Swarm Test Lead with Wrong Industry';
            testLead.Company = 'Swarm Test Company with Wrong Industry';
            testLead.Industry = 'FinServ';
            insert testLead;
            
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testLead.Id and SubscriberId = :currentUser.Id]);
                }
            } 
        
            Lead testLeadSuccess = new Lead();
            testLeadSuccess.LastName = 'Swarm Test Lead with Correct Industry';
            testLeadSuccess.Company = 'Swarm Test Company with Correct Industry';
            testLeadSuccess.Industry = 'SaaS';
            insert testLeadSuccess ;
            
            // Check that swarm was added -- need at least two subscribers (might have more);
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testLeadSuccess.Id and SubscriberId = :currentUser.Id]);
            }          
        }

        tearDown();
    }  

}