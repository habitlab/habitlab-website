(function(){
  var ref$, app, get_proposed_goals, mongodb, all_contributed_interventions, intervention_name_to_data, goal_name_to_interventions, proposed_goals_list;
  ref$ = require('libs/server_common'), app = ref$.app, get_proposed_goals = ref$.get_proposed_goals, mongodb = ref$.mongodb;
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
  app.get('/delete_proposed_goal', function*(){
    var goal_id, ref$, proposed_goals, db;
    goal_id = this.request.query.goal_id;
    if (goal_id == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Need goal_id'
      });
      return;
    }
    ref$ = (yield get_proposed_goals()), proposed_goals = ref$[0], db = ref$[1];
    (yield function(it){
      return proposed_goals.remove({
        _id: mongodb.ObjectID(goal_id)
      }, it);
    });
    this.body = JSON.stringify({
      response: 'done',
      success: true
    });
    return db != null ? db.close() : void 8;
  });
  app.get('/add_proposed_goal', function*(){
    var description, ref$, proposed_goals, db, existing_goals_with_description, new_proposed_goal, result;
    description = this.request.query.description;
    if (description == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Need description'
      });
      return;
    }
    ref$ = (yield get_proposed_goals()), proposed_goals = ref$[0], db = ref$[1];
    existing_goals_with_description = (yield function(it){
      return proposed_goals.find({
        description: description
      }).toArray(it);
    });
    if (existing_goals_with_description.length > 0) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Goal with this description already exists'
      });
      return;
    }
    new_proposed_goal = {
      description: description,
      upvotes: 0,
      downvotes: 0
    };
    result = (yield function(it){
      return proposed_goals.insert(new_proposed_goal, it);
    });
    this.body = JSON.stringify({
      response: 'done',
      success: true,
      result: result
    });
    return db != null ? db.close() : void 8;
  });
  app.get('/get_proposed_goals', function*(){
    var ref$, proposed_goals, db, all_results;
    this.type = 'json';
    ref$ = (yield get_proposed_goals()), proposed_goals = ref$[0], db = ref$[1];
    all_results = (yield function(it){
      return proposed_goals.find({}).toArray(it);
    });
    this.body = JSON.stringify(all_results);
    return db != null ? db.close() : void 8;
  });
  app.get('/upvote_proposed_goal', function*(){
    var goal_id, ref$, proposed_goals, db;
    this.type = 'json';
    goal_id = this.request.query.goal_id;
    if (goal_id == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Need goal_id'
      });
      return;
    }
    ref$ = (yield get_proposed_goals()), proposed_goals = ref$[0], db = ref$[1];
    (yield function(it){
      return proposed_goals.update({
        _id: mongodb.ObjectID(goal_id)
      }, {
        $inc: {
          upvotes: 1
        }
      }, it);
    });
    this.body = JSON.stringify({
      response: 'done',
      success: true
    });
    return db != null ? db.close() : void 8;
  });
  app.get('/downvote_proposed_goal', function*(){
    var goal_id, ref$, proposed_goals, db;
    this.type = 'json';
    goal_id = this.request.query.goal_id;
    if (goal_id == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'Need goal_id'
      });
      return;
    }
    ref$ = (yield get_proposed_goals()), proposed_goals = ref$[0], db = ref$[1];
    (yield function(it){
      return proposed_goals.update({
        _id: mongodb.ObjectID(goal_id)
      }, {
        $inc: {
          downvotes: 1
        }
      }, it);
    });
    this.body = JSON.stringify({
      response: 'done',
      success: true
    });
    return db != null ? db.close() : void 8;
  });
}).call(this);
