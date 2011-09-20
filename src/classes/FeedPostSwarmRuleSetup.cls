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

public with sharing class FeedPostSwarmRuleSetup {

    String triggerText = null;
    String description = null;
    String followOrUnfollow = null;
    String[] usersSelected = new String[]{};
    Boolean notify = false;

    public String getTriggerText() {
        return triggerText;
    }
                    
    public void setTriggerText(String triggerText) { 
        this.triggerText = triggerText; 
    }

    public String getDescription() {
        return description;
    }
                    
    public void setDescription(String description) { 
        this.description = description; 
    }

    public String getFollowOrUnfollow() {
        return followOrUnfollow;
    }
                    
    public void setFollowOrUnfollow(String followOrUnfollow) { 
        this.followOrUnfollow = followOrUnfollow; 
    }

    public List<SelectOption> getFollowOrUnfollowOptions() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Follow', 'Follow'));
        options.add(new SelectOption('Unfollow', 'Unfollow'));
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

    public PageReference saveFeedPostSwarmRule() {

        FeedPostSwarmRuleSetup.addRules(this.getUsersSelected(), this.getTriggerText(), this.getDescription(), 
            this.getFollowOrUnfollow(), this.notify);
            
        // Redirect the user back to the original page
        PageReference pageRef = Page.SwarmRuleSaveSuccess;
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    @future
    public static void addRules(String[] usersSelected, String triggerText, String description, String followOrUnfollow, 
        Boolean notify) {
        
        List<Feed_Post_Swarm_Rule__c> newRules = new List<Feed_Post_Swarm_Rule__c>();
    
        for (String userId : usersSelected) {
            Feed_Post_Swarm_Rule__c rule = new Feed_Post_Swarm_Rule__c();
            rule.User__c = userId;
            rule.Trigger_Text__c = triggerText;
            rule.Description__c = description;
            rule.Follow_or_Unfollow__c = followOrUnfollow;
            rule.Notify_on_Swarm__c = notify;
            newRules.add(rule);
        }
        insert newRules;
    }
}