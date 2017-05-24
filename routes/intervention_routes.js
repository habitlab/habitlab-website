(function(){
  var app, all_contributed_interventions, intervention_name_to_data, goal_name_to_interventions, proposed_goals_list;
  app = require('libs/server_common').app;
  all_contributed_interventions = [
    {
      "name": "reddit/block_gif_links",
      "goal": "reddit/spend_less_time",
      "description": "Blocks links to gifs",
      "numusers": 200,
      "stars": 4.5,
      "comments": [
        {
          "author": "geza",
          "text": "awesome intervention"
        }, {
          "author": "lewin",
          "text": "doubleplusgood"
        }
      ]
    }, {
      "name": "reddit/remove_comments",
      "goal": "reddit/spend_less_time",
      "description": "Removes comments",
      "numusers": 300,
      "stars": 4,
      "comments": [
        {
          "author": "geza",
          "text": "ok-ish? á 漢字"
        }, {
          "author": "lewin",
          "text": "lukewarm review"
        }
      ]
    }
  ];
  intervention_name_to_data = {};
  goal_name_to_interventions = {};
  (function(){
    var i$, ref$, len$, intervention_info, intervention_name, goal_name, results$ = [];
    for (i$ = 0, len$ = (ref$ = all_contributed_interventions).length; i$ < len$; ++i$) {
      intervention_info = ref$[i$];
      intervention_name = intervention_info.name;
      goal_name = intervention_info.goal;
      intervention_name_to_data[intervention_name] = intervention_info;
      if (goal_name_to_interventions[goal_name] == null) {
        goal_name_to_interventions[goal_name] = [];
      }
      results$.push(goal_name_to_interventions[goal_name].push(intervention_name));
    }
    return results$;
  })();
  app.get('/get_contributed_interventions_for_goal', function*(){
    var goal, interventions_list, ref$, intervention_info_list, res$, i$, len$, x;
    this.type = 'json';
    goal = this.request.query.goal;
    interventions_list = (ref$ = goal_name_to_interventions[goal]) != null
      ? ref$
      : [];
    res$ = [];
    for (i$ = 0, len$ = interventions_list.length; i$ < len$; ++i$) {
      x = interventions_list[i$];
      res$.push(intervention_name_to_data[x]);
    }
    intervention_info_list = res$;
    return this.body = JSON.stringify(intervention_info_list);
  });
  proposed_goals_list = [
    {
      id: 0,
      description: 'Sleep more',
      upvotes: 3,
      downvotes: 1
    }, {
      id: 1,
      description: 'Read more',
      upvotes: 2,
      downvotes: 1
    }
  ];
  app.get('/get_proposed_goals', function*(){
    this.type = 'json';
    return this.body = JSON.stringify(proposed_goals_list);
  });
  app.get('/upvote_proposed_goal', function*(){
    var goal_id;
    this.type = 'json';
    goal_id = this.request.query.goal_id;
    if (goal_id == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Need goal_id'
      });
      return;
    }
    proposed_goals_list[goal_id].upvotes += 1;
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.get('/downvote_proposed_goal', function*(){
    var goal_id;
    this.type = 'json';
    goal_id = this.request.query.goal_id;
    if (goal_id == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Need goal_id'
      });
      return;
    }
    proposed_goals_list[goal_id].downvotes += 1;
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
}).call(this);
