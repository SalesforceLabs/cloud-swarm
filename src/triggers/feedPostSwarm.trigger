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
    with contributions from John Kucera <jkucera@salesforce.com>
*/
trigger feedPostSwarm on FeedItem (after insert) {

    List<Id> feedItemIds = new List<Id>();
    for (FeedItem thisFeedItem : Trigger.New) {
        feedItemIds.add(thisFeedItem.ParentId);
        System.debug('add ' + thisFeedItem.ParentId);
    }// for
    
    // No SOQL on FeedItems, can't do this:
    //    List<FeedItem> feedItems = [SELECT FeedItemId, ParentId, TextPost, OwnerId
    //        FROM FeedPost WHERE Type = 'TextPost' AND Id IN :feedItemIds];
    List<FeedItem> feedItems = Trigger.New;

    List<Feed_Post_Swarm_Rule__c> rules = [select Trigger_Text__c, user__c, ownerId, Notify_on_Swarm__c, Follow_or_Unfollow__c
        from Feed_Post_Swarm_Rule__c WHERE user__r.IsActive = true];
    List<EntitySubscription> subs = new List<EntitySubscription>();
    List<EntitySubscription> unsubs = new List<EntitySubscription>();
    
    // Get all subscriptions and put in string concatenating subscriber + object ID
    List<EntitySubscription> existingfeedItemSubList = [select SubscriberId, ParentId from EntitySubscription where ParentId in :feedItemIds limit 1000];
    
    Map<String, EntitySubscription> existingFeedItemSubs = new Map<String, EntitySubscription>();
    for (EntitySubscription es : existingfeedItemSubList) {
        existingFeedItemSubs.put((String)es.SubscriberId + es.ParentId, es);
    }//for

    List<FeedPost> feedNotifications = new List<FeedPost>();
    
    for (FeedItem thisFeedItem : feedItems) {
    
        for (Feed_Post_Swarm_Rule__c rule : rules) {

           System.debug(thisFeedItem.Type + ' = ' + thisFeedItem.Body + ' - ' + rule.Trigger_Text__c);

            if ((thisFeedItem.Type).equals('TextPost') && (thisFeedItem.Body).contains(rule.Trigger_Text__c)) {
                
                if (rule.Follow_or_Unfollow__c.equals('Follow')) {
                    if (existingFeedItemSubs.containsKey((string)rule.User__c + thisFeedItem.ParentId) == false) {
    
                        EntitySubscription newSub = new EntitySubscription(parentId = thisFeedItem.ParentId, SubscriberId = rule.User__c);
                        subs.add(newSub);
                        existingFeedItemSubs.put((String)rule.User__c + thisFeedItem.ParentId, newSub);
                        
                        if (rule.Notify_on_Swarm__c == true) {
                            // Add swarming notification to user's feed
                            FeedPost swarmNotification = new FeedPost();
                            swarmNotification.Type = 'LinkPost';
                            swarmNotification.ParentId = rule.User__c;
                            swarmNotification.Title = 'Link to Record Swarmed';
                            swarmNotification.Body = 'You have automatically swarmed a record.';
                            swarmNotification.LinkUrl = '/' + thisFeedItem.ParentId;
                            feedNotifications.add(swarmNotification);
    
                        }// if 4
                    }//if 3
                } else {
                    // Unfollow Rule
           System.debug(existingFeedItemSubs);
                    if (existingFeedItemSubs.containsKey((string)rule.User__c + thisFeedItem.ParentId) == true) {
                        unsubs.add(existingFeedItemSubs.get((string)rule.User__c + thisFeedItem.ParentId));
                        existingFeedItemSubs.remove((String)rule.User__c + thisFeedItem.ParentId);
                    }
                }
            }//if 1
        }//for 2  rules
    }//for 1 oppty's

    try {
        insert subs;
        insert feedNotifications;
        delete unsubs;
    } catch (DMLException e) {
        system.debug('Feed Item Swarm subscriptions were not all inserted successfully.  Error: '+e);
    }//catch
}