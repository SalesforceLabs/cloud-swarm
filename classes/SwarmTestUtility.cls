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

public with sharing class SwarmTestUtility {

    /*
        A random user is useful for testing in order to be 
        sure that you are able to see data across posts regardless
        of follow status.
    */
    public static User createTestUser() {
        Profile p = [Select Id, Name from Profile where Name = 'System Administrator'];
        return SwarmTestUtility.createTestUser(p);
    }
    
    public static User createTestUser(Profile p) {
        
        String namePrefix = createRandomWord();
        
        AggregateResult[] userCount = [Select count(id) userCount From user where username like :namePrefix];
        
        Object users = userCount[0].get('userCount');
        
        User testUser = new User();
        testUser.Email = 'test@test.com';
        testUser.Username = namePrefix+users+'@testuser.test';

        testUser.LastName = 'test';
        testUser.Alias = 'test';
        testUser.ProfileId = p.Id;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.TimeZoneSidKey = 'America/Chicago';
        testUser.EmailEncodingKey = 'UTF-8';
        insert testUser;
        return testUser;
    }

    public static Group createGroup(String name) {
        Group testGroup = new Group();
            testGroup.name = name;
            testGroup.type = 'Regular';
            insert testGroup;
            
            return testGroup;
    }
    
    public static GroupMember joinGroup(User u, Group g) {
        
            GroupMember member1 = new GroupMember();
            member1.GroupId = g.Id;
            member1.UserOrGroupId = u.Id;
            insert member1;
            return member1;
        
    }
    
    /*
        Random words are required for testing 
        as you will likely run into any word I can insert
        during a test class and produce false test results.
    */
        
    public static String createRandomWord() {
        
        String ret = 'word' + math.rint(math.random() * 100000);
        
        return ret;
        
    }
    
    //TEST METHODS
    
    static TestMethod void testRandomWord() {
        
        System.assert(SwarmTestUtility.createRandomWord() != SwarmTestUtility.createRandomWord());
    }
    
    static TestMethod void testCreateUser() {
        
        User u = SwarmTestUtility.createTestUser();
        
        System.assert(u.id != null);
        
    }
    
    static TestMethod void testCreateGroup() {
        
        Group g = SwarmTestUtility.createGroup('name'+SwarmTestUtility.createRandomWord());
        
        System.assert(g.id != null);
    }

    static TestMethod void testJoinGroup() {
        
        Group g = SwarmTestUtility.createGroup('name'+SwarmTestUtility.createRandomWord());
        
        User u = SwarmTestUtility.createTestUser();
        
        GroupMember gm = SwarmTestUtility.joinGroup(u, g);
        
        System.assert(gm.id != null);
        
    }
    

    
}