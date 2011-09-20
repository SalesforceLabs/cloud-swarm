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

public class CaseSwarmTest {

    static List<User> testUsers = new List<User>();

    static User user1 = null;
    static User user2 = null;
    
    static final String groupName = '## Swarm My Test Group ##';
    static Id groupId;

    static void buildUp() {
        CaseSwarmTest.user1 = SwarmTestUtility.createTestUser();
        CaseSwarmTest.user2 = SwarmTestUtility.createTestUser();
        user2.Manager = user1;
    }   

    static void tearDown() {}

    static testMethod void testGetOptions() {
        CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();

        // Check that options are populating
        System.assert(0 < controller.getStep1Options().size());
        System.assert(0 < controller.getStatusOptions().size());
        System.assert(0 < controller.getPriorityOptions().size());
        System.assert(0 < controller.getTypeOptions().size());
        System.assert(0 < controller.getUserOptions().getSize());
    }
    
    static testMethod void testAllCases() {

        buildUp();

        System.runAs(CaseSwarmTest.user1) {

            Test.startTest();
            PageReference pageRef = Page.CaseSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();
    
            controller.setStep1('All Cases');
            System.assertEquals('All Cases', controller.getStep1());
            controller.setUsersSelected(new String[]{CaseSwarmTest.user1.Id, CaseSwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(CaseSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(CaseSwarmTest.user2.Id));
            String nextPage = controller.action().getUrl();
    
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
    
            // Verify rules were added
            System.assertEquals(2, [select count() from Case_Swarm_Rule__c where CreatedById = :user1.Id]);
        }

    }

    static testMethod void testAllCases2() {

        buildUp();

        System.runAs(CaseSwarmTest.user1) {

            // Create a case
            Test.startTest();
            Case testCase = new Case();
            insert testCase;

            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testCase.Id and SubscriberId = :currentUser.Id]);
            }
        }      
        
        tearDown();
    }
    
    static testMethod void testOnlyAccountsIOwn() {

        buildUp();
        
        System.runAs ( user1 ) {

            Test.startTest();
            PageReference pageRef = Page.CaseSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();
        
            controller.setStep1('Only Cases for Accounts I Own');
            System.assertEquals('Only Cases for Accounts I Own', controller.getStep1());
            controller.setUsersSelected(new String[]{CaseSwarmTest.user1.Id, CaseSwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(CaseSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(CaseSwarmTest.user2.Id));
            String nextPage = controller.action().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
        
            // Verify rules were added
            System.assertEquals(2, [select count() from Case_Swarm_Rule__c where CreatedById = :user1.id]);
        
        }
        
        tearDown();
    }

    static testMethod void testOnlyAccountsIOwn2() {

        buildUp();
        
        System.runAs ( user1 ) {

            // Create a case with no account (no followers)
            Test.startTest();
            Case testCase = new Case();
            insert testCase;

            for (User currentUser : testUsers) {
                System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testCase.Id and SubscriberId = :currentUser.Id]);
            }
            
            // Create a case with an account
            Account myAccount = new Account();
            myAccount.name = 'Test Account';
            myAccount.ownerId = user1.Id;
            insert myAccount;
        
            Case testCaseWithAccount = new Case();
            testCaseWithAccount.AccountId = myAccount.Id;
            insert testCaseWithAccount;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testCaseWithAccount.Id and SubscriberId = :currentUser.Id]);
            }
        }
        
        tearDown();

    }


    static testMethod void testOwnedByDirectReport() {

        buildUp();
        
        System.runAs(user1) {

            Test.startTest();
            PageReference pageRef = Page.CaseSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();
    
            System.assert(0 < controller.getStatusOptions().size());
        
            controller.setStep1('Only Cases owned by my direct reports');
            System.assertEquals('Only Cases owned by my direct reports', controller.getStep1());
            controller.setUsersSelected(new String[]{CaseSwarmTest.user1.Id, CaseSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(CaseSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(CaseSwarmTest.user2.Id));
            String nextPage = controller.action().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
        
            // Verify rules were added
            System.assertEquals(2, [select count() from Case_Swarm_Rule__c where CreatedById = :user1.id]);
        }
        
        tearDown();
    }    

    static testMethod void testOwnedByDirectReport2() {

        buildUp();
        
        System.runAs(user1) {

            // Create a case with wrong status (no followers)
            Test.startTest();
            Case testCase = new Case();
            insert testCase;
            for (User currentUser : testUsers) {
                System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testCase.Id and SubscriberId = :currentUser.Id]);
            }      
        }
            
        System.runAs(user2) {
        
            Case testCaseSuccess = new Case();
            insert testCaseSuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testCaseSuccess.Id and SubscriberId = :currentUser.Id]);
            }

        }
        
        tearDown();
    }


    static testMethod void testStatus() {

        buildUp();
        
        System.runAs(user1) {

            Test.startTest();
            PageReference pageRef = Page.CaseSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();
    
            System.assert(0 < controller.getStatusOptions().size());
        
            controller.setStep1('Only Cases with a certain Status');
            System.assertEquals('Only Cases with a certain Status', controller.getStep1());
            controller.setWithStatus('Test Status');
            System.assertEquals('Test Status', controller.getWithStatus());
            controller.setUsersSelected(new String[]{CaseSwarmTest.user1.Id, CaseSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(CaseSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(CaseSwarmTest.user2.Id));
            String nextPage = controller.action().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
        
            // Verify rules were added
            System.assertEquals(2, [select count() from Case_Swarm_Rule__c where CreatedById = :user1.id]);
        }
        
        tearDown();
    }    

    static testMethod void testStatus2() {

        buildUp();
        
        System.runAs(user1) {

            // Create a case with wrong status (no followers)
            Test.startTest();
            Case testCase = new Case();
            testCase.Status = 'Different Status';
            insert testCase;
            for (User currentUser : testUsers) {
                System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testCase.Id and SubscriberId = :currentUser.Id]);
            }      
            
        
            Case testCaseSuccess = new Case();
            testCaseSuccess.Status = 'Test Status';
            insert testCaseSuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testCaseSuccess.Id and SubscriberId = :currentUser.Id]);
            }

        }
        
        tearDown();
    }

    static testMethod void testPriority() {

        buildUp();
        
        System.runAs(user1) {

            Test.startTest();
            PageReference pageRef = Page.CaseSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();
    
            System.assert(0 < controller.getStatusOptions().size());
        
            controller.setStep1('Only Cases with a certain Priority');
            System.assertEquals('Only Cases with a certain Priority', controller.getStep1());
            controller.setWithPriority('Test Priority');
            System.assertEquals('Test Priority', controller.getWithPriority());
            controller.setUsersSelected(new String[]{CaseSwarmTest.user1.Id, CaseSwarmTest.user2.Id});
            controller.setNotify(true);
            System.assertEquals(true, controller.getNotify());
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(CaseSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(CaseSwarmTest.user2.Id));
            String nextPage = controller.action().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
        
            // Verify rules were added
            System.assertEquals(2, [select count() from Case_Swarm_Rule__c where CreatedById = :user1.id]);
        }
        
        tearDown();
    }  

    static testMethod void testPriority2() {

        buildUp();
        
        System.runAs(user1) {

            // Create a case with wrong status (no followers)
            Test.startTest();
            Case testCase = new Case();
            testCase.Priority = 'Different Priority';
            insert testCase;
        
            
            for (User currentUser : testUsers) {
                System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testCase.Id and SubscriberId = :currentUser.Id]);
            }   
        
            Case testCaseSuccess = new Case();
            testCaseSuccess.Priority = 'Test Priority';
            insert testCaseSuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testCaseSuccess.Id and SubscriberId = :currentUser.Id]);
            }           
        }

        tearDown();
    }

    static testMethod void testType() {

        buildUp();
        
        System.runAs(user1) {

            Test.startTest();
            PageReference pageRef = Page.CaseSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            CaseSwarmRuleSetup controller = new CaseSwarmRuleSetup();
    
            System.assert(0 < controller.getTypeOptions().size());
        
            controller.setStep1('Only Cases of a certain Type');
            System.assertEquals('Only Cases of a certain Type', controller.getStep1());
            controller.setWithType('Test Type');
            System.assertEquals('Test Type', controller.getWithType());
            controller.setUsersSelected(new String[]{CaseSwarmTest.user1.Id, CaseSwarmTest.user2.Id});
    
            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(CaseSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(CaseSwarmTest.user2.Id));
            String nextPage = controller.action().getUrl();
        
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
            
            // Verify rules were added
            System.assertEquals(2, [select count() from Case_Swarm_Rule__c where createdbyid = :user1.id]);
        }
        
        tearDown();
    }  

    static testMethod void testType2() {
        buildUp();
        
        System.runAs(user1) {

            // Create a case with wrong status (no followers)
            Test.startTest();
            Case testCase = new Case();
            testCase.Type = 'Different Type';
            insert testCase;
        
            for (User currentUser : testUsers) {
                System.assertEquals(0, [select count() from EntitySubscription where ParentId = :testCase.Id and SubscriberId = :currentUser.id]);
            }
        
            Case testCaseSuccess = new Case();
            testCaseSuccess.Type= 'Test Type';
            insert testCaseSuccess ;
        
            // Check that swarm was added
            Test.stopTest();
            for (User currentUser : testUsers ) {
                System.assertEquals(1, [select count() from EntitySubscription where ParentId = :testCaseSuccess.Id and subscriberId = :currentUser.Id]);
            }

        }
        
        tearDown();
    }
}