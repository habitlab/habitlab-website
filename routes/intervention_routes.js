(function(){
  var ref$, app, get_proposed_goals, mongodb, need_query_properties, need_query_property, all_contributed_interventions, intervention_name_to_data, goal_name_to_interventions, proposed_goals_list;
  ref$ = require('libs/server_common'), app = ref$.app, get_proposed_goals = ref$.get_proposed_goals, mongodb = ref$.mongodb, need_query_properties = ref$.need_query_properties, need_query_property = ref$.need_query_property;
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
  app.get('/add_contributed_intervention', function*(){
    var ref$, name, goal, description, numusers, stars, comments, new_contributed_intervention, result;
    ref$ = this.request.query, name = ref$.name, goal = ref$.goal, description = ref$.description, numusers = ref$.numusers, stars = ref$.stars, comments = ref$.comments;
    if (need_query_properties(this, ['name', 'goal', 'description'])) {
      return;
    }
    numusers == null && (numusers = 0);
    stars == null && (stars = 0);
    comments == null && (comments = []);
    new_contributed_intervention = {
      name: name,
      goal: goal,
      description: description,
      numusers: numusers,
      stars: stars,
      comments: comments
    };
    result = (yield function(it){
      return proposed_goals.insert(new_contributed_intervention, it);
    });
    this.body = JSON.stringify({
      response: 'done',
      success: true
    });
    return typeof db != 'undefined' && db !== null ? db.close() : void 8;
  });
  app.get('/delete_contributed_intervention', function*(){
    var intervention_id, ref$, contributed_interventions, db;
    intervention_id = this.request.query.intervention_id;
    if (need_query_property(this, 'intervention_id')) {
      return;
    }
    ref$ = (yield get_contributed_interventions()), contributed_interventions = ref$[0], db = ref$[1];
    (yield function(it){
      return contributed_interventions.remove({
        _id: mongodb.ObjectID(intervention_id)
      }, it);
    });
    this.body = JSON.stringify({
      response: 'done',
      success: true
    });
    return db != null ? db.close() : void 8;
  });
  app.get('/get_all_contributed_interventions', function*(){
    var ref$, contributed_interventions, db, all_results;
    this.type = 'json';
    ref$ = (yield get_contributed_interventions()), contributed_interventions = ref$[0], db = ref$[1];
    all_results = (yield function(it){
      return contributed_interventions.find({}).toArray(it);
    });
    this.body = JSON.stringify(all_results);
    return db != null ? db.close() : void 8;
  });
  app.get('/get_contributed_interventions_for_goal', function*(){
    var goal, ref$, contributed_interventions, db, all_results;
    this.type = 'json';
    goal = this.request.query.goal;
    if (need_query_property(this, 'goal')) {
      return;
    }
    ref$ = (yield get_contributed_interventions()), contributed_interventions = ref$[0], db = ref$[1];
    all_results = (yield function(it){
      return contributed_interventions.find({
        goal: goal
      }).toArray(it);
    });
    this.body = JSON.stringify(all_results);
    return db != null ? db.close() : void 8;
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
    if (need_query_property(this, 'goal_id')) {
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
    if (need_query_property(this, 'description')) {
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
        error: 'Goal with this description already exists',
        result: existing_goals_with_description[0]
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
    if (need_query_property(this, 'goal_id')) {
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
    if (need_query_property(this, 'goal_id')) {
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
