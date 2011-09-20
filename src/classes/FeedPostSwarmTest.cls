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

public class FeedPostSwarmTest {

    static List<User> testUsers = new List<User>();

    static User user1 = null;
    static User user2 = null;
    
    static void buildUp() {
        FeedPostSwarmTest.user1 = SwarmTestUtility.createTestUser();
        FeedPostSwarmTest.user2 = SwarmTestUtility.createTestUser();
        user2.Manager = user1;
        
        
    }   

    static void tearDown() {}

    static testMethod void testGetOptions() {
        FeedPostSwarmRuleSetup controller = new FeedPostSwarmRuleSetup();

        // Check that options are populating
        System.assert(0 < controller.getFollowOrUnfollowOptions().size());
        System.assert(0 < controller.getUserOptions().getSize());
    }
    
    static testMethod void testFollowAndUnfollow() {

        buildUp();

        System.runAs(FeedPostSwarmTest.user1) {

            Test.startTest();
            PageReference pageRef = Page.FeedPostSwarmRuleSetup;
            Test.setCurrentPage(pageRef);
          
            FeedPostSwarmRuleSetup controller = new FeedPostSwarmRuleSetup();
    
            // Create Following rule
            controller.setTriggerText('ABC123');
            System.assertEquals('ABC123', controller.getTriggerText());
            controller.setDescription('This is a test of the feed post auto-follow functionality.');
            System.assertEquals('This is a test of the feed post auto-follow functionality.', controller.getDescription());
            controller.setFollowOrUnfollow('Follow');
            System.assertEquals('Follow', controller.getFollowOrUnfollow());
            controller.setNotify(true);
            System.assertEquals(true, controller.getNotify());

            controller.setUsersSelected(new String[]{FeedPostSwarmTest.user1.Id, FeedPostSwarmTest.user2.Id});

            Set<String> selectedUsers = new Set<String>{};
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(FeedPostSwarmTest.user1.Id));
            System.assert(selectedUsers.contains(FeedPostSwarmTest.user2.Id));
            String nextPage = controller.saveFeedPostSwarmRule().getUrl();
    
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || nextPage == '/apex/cloudswarm__swarmrulesavesuccess');

            Test.setCurrentPage(pageRef);
          
            // Create Unfollow rule
            controller.setTriggerText('XYZ789');
            System.assertEquals('XYZ789', controller.getTriggerText());
            controller.setDescription('This is a test of the feed post auto-unfollow functionality.');
            System.assertEquals('This is a test of the feed post auto-unfollow functionality.', 
                controller.getDescription());
            controller.setFollowOrUnfollow('Unfollow');
            System.assertEquals('Unfollow', controller.getFollowOrUnfollow());

            controller.setUsersSelected(new String[]{FeedPostSwarmTest.user2.Id});

            selectedUsers.clear();
            selectedUsers.addAll(controller.getUsersSelected());
            System.assert(selectedUsers.contains(FeedPostSwarmTest.user2.Id));
            nextPage = controller.saveFeedPostSwarmRule().getUrl();
    
            // Verify that the success page displays  
            System.assert(nextPage == '/apex/swarmrulesavesuccess' || 
                nextPage == '/apex/cloudswarm__swarmrulesavesuccess');
            Test.stopTest();
    
            // Verify rules were added
            System.assertEquals(3, [select count() from Feed_Post_Swarm_Rule__c where CreatedById = :user1.Id]);

            // Create a case
            Case testCase = new Case();
            insert testCase;
            
            // Test Following rule
            FeedItem testPost = new FeedItem();
            testPost.Type = 'TextPost';
            testPost.ParentId = testCase.Id;
            testPost.Body = 'ABC123';
            insert testPost;        
            
            // Check that swarm was added
            System.assertEquals(1, [select count() from EntitySubscription 
                where ParentId = :testCase.Id and SubscriberId = :user1.Id]);
            System.assertEquals(1, [select count() from EntitySubscription 
                where ParentId = :testCase.Id and SubscriberId = :user2.Id]);

            // Test Unfollowing rule (may not work with conflicting CaseSwarmRules depending on order of execution?)
            FeedItem testPost2 = new FeedItem();
            testPost2.Type = 'TextPost';
            testPost2.ParentId = testCase.Id;
            testPost2.Body = 'XYZ789';
            insert testPost2;        
            
            // Check that swarm was added
            System.assertEquals(1, [select count() from EntitySubscription 
                where ParentId = :testCase.Id and SubscriberId = :user1.Id]);
            System.assertEquals(0, [select count() from EntitySubscription 
                where ParentId = :testCase.Id and SubscriberId = :user2.Id]);
        }      
        
        tearDown();
    }
 
}