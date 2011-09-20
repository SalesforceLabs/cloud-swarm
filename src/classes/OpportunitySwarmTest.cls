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

public class OpportunitySwarmTest {

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
        OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();

        // Check that options are populating
        System.assert(0 < controller.getStageOptions().size());
        System.assert(0 < controller.getTypeOptions().size());
        System.assert(0 < controller.getUserOptions().getSize());
    }

    static testMethod void testAllOpportunities() {

        buildUp();

        System.runAs ( user1 ) {

            Test.startTest();
            PageReference pageRef = Page.OpptySwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();
    
            controller.setStep1('All Opportunities');
            System.assertEquals('All Opportunities', controller.getStep1());
            controller.setUsersSelected(new String[]{OpportunitySwarmTest.user1.Id, OpportunitySwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user1.Id));
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user2.Id));
            String nextPage = controller.saveOpptySwarmRule().getUrl();
    
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
    
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Opportunity_Swarm_Rule__c where CreatedById = :user1.Id]);
        }
        
        tearDown();
    }

    static testMethod void testAllOpportunities2() {

        buildUp();

        System.runAs ( user1 ) {

            Test.startTest();

            // Create an oppty
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Name = 'Swarm Test Opp';
            testOpportunity.StageName = 'Different Stage';
            testOpportunity.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunity.Amount = 555;
            insert testOpportunity;
            
            // Check that swarm was added -- note that for test resiliance you need to cycle through the group
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :currentUser.Id]);
            }
        }
        
        tearDown();
    }
    
        
    static testMethod void testOnlyAccountsIOwn() {

        buildUp();
        
        System.runAs ( user1 ) {

            Test.startTest();
            PageReference pageRef = Page.OpptySwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();
        
            controller.setStep1('Only Opportunities for Accounts I Own');
            System.assertEquals('Only Opportunities for Accounts I Own', controller.getStep1());
            controller.setUsersSelected(new String[]{OpportunitySwarmTest.user1.Id, OpportunitySwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user1.Id));
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user2.Id));
            String nextPage = controller.saveOpptySwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Opportunity_Swarm_Rule__c where CreatedById = :user1.id]);
        }
        
        tearDown();
    }

    static testMethod void testOnlyAccountsIOwn2() {

        buildUp();
        
        System.runAs ( user1 ) {
            Test.startTest();

            // Create an oppty with no account (no followers)
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Name = 'Swarm Test Opp';
            testOpportunity.StageName = 'Different Stage';
            testOpportunity.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunity.Amount = 555;
            insert testOpportunity;
            
            //the owner show created it will follow it
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :currentUser.Id]);
                }
            }
        
            // Create an Opportunity with an account
            Account myAccount = new Account();
            myAccount.name = 'Test Account';
            myAccount.ownerId = user1.Id;
            insert myAccount;
        
            Opportunity testOpportunityWithAccount = new Opportunity();
            testOpportunityWithAccount.AccountId = myAccount.Id;
            testOpportunityWithAccount.Name = 'Swarm Failed Test Opp';
            testOpportunityWithAccount.StageName = 'Different Stage';
            testOpportunityWithAccount.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunityWithAccount.Amount = 555;
            insert testOpportunityWithAccount;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testOpportunityWithAccount.Id and SubscriberId = :currentUser.Id]);
            }
        }
        
        tearDown();
    }


    static testMethod void testOwnedByDirectReports() {

        buildUp();
        
        System.runAs ( user1 ) {

            Test.startTest();
            PageReference pageRef = Page.OpptySwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();
        
            controller.setStep1('Only Opportunities owned by my direct reports');
            System.assertEquals('Only Opportunities owned by my direct reports', controller.getStep1());
            controller.setUsersSelected(new String[]{OpportunitySwarmTest.user1.Id, OpportunitySwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user1.Id));
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user2.Id));
            String nextPage = controller.saveOpptySwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Opportunity_Swarm_Rule__c where CreatedById = :user1.id]);
        }
        
        tearDown();
    }

    static testMethod void testOwnedByDirectReports2() {

        buildUp();
        
        System.runAs ( user1 ) {
            Test.startTest();

            // Create an oppty for the manager (will not be followed)
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Name = 'Swarm Test Opp';
            testOpportunity.StageName = 'Different Stage';
            testOpportunity.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunity.Amount = 555;
            insert testOpportunity;
            
            //the owner show created it will follow it
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :currentUser.Id]);
                }
            }
        }
        
        System.runAs ( user2 ) {
            // Create an oppty for the direct report (will auto-follow)
            Opportunity testOpportunitySuccess= new Opportunity();
            testOpportunitySuccess.Name = 'Swarm Failed Test Opp';
            testOpportunitySuccess.StageName = 'Different Stage';
            testOpportunitySuccess.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunitySuccess.Amount = 555;
            insert testOpportunitySuccess;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testOpportunitySuccess.Id and SubscriberId = :currentUser.Id]);
            }
        }
        
        tearDown();
    }
 
     
    static testMethod void testAmount() {

        buildUp();

        System.runAs ( user1 ) {

            Test.startTest();
            PageReference pageRef = Page.OpptySwarmRuleSetup;
            Test.setCurrentPage(pageRef);

            OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();
    
            controller.setStep1('Only Opportunities above a certain amount');
            System.assertEquals('Only Opportunities above a certain amount', controller.getStep1());
            controller.setAmount('50000');
            System.assertEquals('50000', controller.getAmount());
            controller.setNotify(true);
            System.assertEquals(true, controller.getNotify());
            controller.setUsersSelected(new String[]{OpportunitySwarmTest.user1.Id, OpportunitySwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user1.Id));
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user2.Id));
            String nextPage = controller.saveOpptySwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Opportunity_Swarm_Rule__c where CreatedById = :user1.Id]);
        }
        
        tearDown();
    }    

    static testMethod void testAmount2() {

        buildUp();

        System.runAs ( user1 ) {

            Test.startTest();

            // Create an Opportunity with wrong status (no followers)
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Amount = 1;
            testOpportunity.Name = 'Swarm Failed Test Opp';
            testOpportunity.StageName = 'Different Stage';
            testOpportunity.CloseDate = Date.newInstance(2010, 03, 26);
            insert testOpportunity;
        
            //users should not be included.
            for (User currentUser : testUsers) {
                System.debug('SampleId ' + currentUser.id + ', '+ user1.Id);
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :currentUser.Id]);
                }
            }    
        
            Opportunity testOpportunitySuccess = new Opportunity();
            testOpportunitySuccess.Amount = 50000;
            testOpportunitySuccess.Name = 'Swarm Test Opp';
            testOpportunitySuccess.StageName = 'Different Stage';
            testOpportunitySuccess.CloseDate = Date.newInstance(2010, 03, 26);
            insert testOpportunitySuccess ;
        
            // Check that swarm was added    
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testOpportunitySuccess.Id and SubscriberId = :currentUser.Id]);
            }  
        }
        
        tearDown();
    }    

    static testMethod void testStage() {

        buildUp();
        
        System.runAs ( user1 ) {
        
            Test.startTest();
            PageReference pageRef = Page.OpptySwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();
    
            System.assert(0 < controller.getStageOptions().size());
        
            controller.setStep1('Only Opportunities that reach a certain stage in the sales process');
            System.assertEquals('Only Opportunities that reach a certain stage in the sales process', 
                controller.getStep1());
            controller.setWithStage('Test Stage');
            System.assertEquals('Test Stage', controller.getWithStage());
                controller.setUsersSelected(new String[]{OpportunitySwarmTest.user1.Id, OpportunitySwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user1.Id));
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user2.Id));
            String nextPage = controller.saveOpptySwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Opportunity_Swarm_Rule__c where CreatedById = :user1.Id]);
        }
        
        tearDown();
    }  

    static testMethod void testStage2() {

        buildUp();
        
        System.runAs ( user1 ) {
        
            Test.startTest();

            // Create an Opportunity with wrong status (no followers)
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Name = 'Swarm Failed Test Opp';
            testOpportunity.StageName = 'Different Stage';
            testOpportunity.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunity.Amount = 555;
            insert testOpportunity;
        
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :currentUser.Id]);
                }
            }
            
        
            Opportunity testOpportunitySuccess = new Opportunity();
            testOpportunitySuccess.Name = 'Swarm Test Opp';
            testOpportunitySuccess.StageName = 'Test Stage';
            testOpportunitySuccess.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunitySuccess.Amount = 555;
            insert testOpportunitySuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testOpportunitySuccess.Id and SubscriberId = :currentUser.Id]);
            }  
        }
        
        tearDown();
    }  


    static testMethod void testType() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();
            PageReference pageRef = Page.OpptySwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            OpptySwarmRuleSetup controller = new OpptySwarmRuleSetup();
    
            System.assert(0 < controller.getTypeOptions().size());
        
            controller.setStep1('Only Opportunities of a certain Type');
            System.assertEquals('Only Opportunities of a certain Type', controller.getStep1());
            controller.setWithType('Test Type');
            System.assertEquals('Test Type', controller.getWithType());
            controller.setUsersSelected(new String[]{OpportunitySwarmTest.user1.Id, OpportunitySwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user1.Id));
            System.assert(selectedUsers.contains(OpportunitySwarmTest.user2.Id));
            String nextPage = controller.saveOpptySwarmRule().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
        
            // Verify rules were added
            Test.stopTest();
            System.assertEquals(2, [select count() from Opportunity_Swarm_Rule__c where CreatedById = :user1.Id]);
        }

        tearDown();
    }  

    static testMethod void testType2() {

        buildUp();
        
        System.runAs ( user1 ) {
            
            Test.startTest();

            // Create an Opportunity with wrong status (no followers)
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Type = 'Different Type';
            testOpportunity.Name = 'Swarm Failed Test Opp';
            testOpportunity.StageName = 'Different Stage';
            testOpportunity.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunity.Amount = 555;
            insert testOpportunity;
            
            System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :user1.Id]);
            for (User currentUser : testUsers) {
                if (currentUser.Id != user1.Id) {
                    System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testOpportunity.Id and SubscriberId = :currentUser.Id]);
                }
            } 
        
            Opportunity testOpportunitySuccess = new Opportunity();
            testOpportunitySuccess.Type= 'Test Type';
            testOpportunitySuccess.Name = 'Swarm Test Opp';
            testOpportunitySuccess.StageName = 'Different Stage';
            testOpportunitySuccess.CloseDate = Date.newInstance(2010, 03, 26);
            testOpportunitySuccess.Amount = 555;
            insert testOpportunitySuccess ;
            
            // Check that swarm was added -- need at least two subscribers (might have more);
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testOpportunitySuccess.Id and SubscriberId = :currentUser.Id]);
            }          
        }

        tearDown();
    }  
}