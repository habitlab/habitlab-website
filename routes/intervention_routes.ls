{
  app
  get_proposed_goals
  mongodb
  need_query_properties
  need_query_property
} = require 'libs/server_common'

require! {
  n2p
}

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
      },
      {
        "author": "lewin",
        "text": "doubleplusgood"
      }
    ]
  },
  {
    "name": "reddit/remove_comments",
    "goal": "reddit/spend_less_time",
    "description": "Removes comments",
    "numusers": 300,
    "stars": 4,
    "comments": [
      {
        "author": "geza",
        "text": "ok-ish? á 漢字"
      },
      {
        "author": "lewin",
        "text": "lukewarm review"
      }
    ]
  }
]

intervention_name_to_data = {}
goal_name_to_interventions = {}
do ->
  for intervention_info in all_contributed_interventions
    intervention_name = intervention_info.name
    goal_name = intervention_info.goal
    intervention_name_to_data[intervention_name] = intervention_info
    if not goal_name_to_interventions[goal_name]?
      goal_name_to_interventions[goal_name] = []
    goal_name_to_interventions[goal_name].push intervention_name

app.get '/add_contributed_intervention', (ctx) ->>
  {name, goal, description, numusers, stars, comments} = ctx.request.query
  if need_query_properties this, ['name', 'goal', 'description']
    return
  numusers ?= 0
  stars ?= 0
  comments ?= []
  new_contributed_intervention = {
    name
    goal
    description
    numusers
    stars
    comments
  }
  result = await n2p -> proposed_goals.insert(new_contributed_intervention, it)
  ctx.body = JSON.stringify {response: 'done', success: true}
  db?close()

app.get '/delete_contributed_intervention', (ctx) ->>
  {intervention_id} = ctx.request.query
  if need_query_property ctx, 'intervention_id'
    return
  [contributed_interventions, db] = await get_contributed_interventions()
  await n2p -> contributed_interventions.remove({_id: mongodb.ObjectID(intervention_id)}, it)
  ctx.body = JSON.stringify {response: 'done', success: true}
  db?close()

app.get '/get_all_contributed_interventions', (ctx) ->>
  ctx.type = 'json'
  [contributed_interventions, db] = await get_contributed_interventions()
  all_results = await n2p -> contributed_interventions.find({}).toArray(it)
  ctx.body = JSON.stringify(all_results)
  db?close()

app.get '/get_contributed_interventions_for_goal', (ctx) ->>
  ctx.type = 'json'
  {goal} = ctx.request.query
  if need_query_property ctx, 'goal'
    return
  [contributed_interventions, db] = await get_contributed_interventions()
  all_results = await n2p -> contributed_interventions.find({goal: goal}).toArray(it)
  ctx.body = JSON.stringify(all_results)
  db?close()

proposed_goals_list = [
  {
    id: 0
    description: 'Sleep more'
    upvotes: 3
    downvotes: 1
  }
  {
    id: 1
    description: 'Read more'
    upvotes: 2
    downvotes: 1
  }
]

app.get '/delete_proposed_goal', (ctx) ->>
  {goal_id} = ctx.request.query
  if need_query_property ctx, 'goal_id'
    return
  [proposed_goals, db] = await get_proposed_goals()
  await n2p -> proposed_goals.remove({_id: mongodb.ObjectID(goal_id)}, it)
  ctx.body = JSON.stringify {response: 'done', success: true}
  db?close()

app.get '/add_proposed_goal', (ctx) ->>
  {description} = ctx.request.query
  if need_query_property ctx, 'description'
    return
  [proposed_goals, db] = await get_proposed_goals()
  existing_goals_with_description = await n2p -> proposed_goals.find({description: description}).toArray(it)
  if existing_goals_with_description.length > 0
    ctx.body = JSON.stringify {response: 'error', error: 'Goal with this description already exists', result: existing_goals_with_description[0]}
    return
  new_proposed_goal = {
    description: description
    upvotes: 0
    downvotes: 0
  }
  result = await n2p -> proposed_goals.insert(new_proposed_goal, it)
  ctx.body = JSON.stringify {response: 'done', success: true, result: result}
  db?close()

app.get '/get_proposed_goals', (ctx) ->>
  ctx.type = 'json'
  [proposed_goals, db] = await get_proposed_goals()
  all_results = await n2p -> proposed_goals.find({}).toArray(it)
  ctx.body = JSON.stringify(all_results)
  db?close()

app.get '/upvote_proposed_goal', (ctx) ->>
  ctx.type = 'json'
  {goal_id} = ctx.request.query
  if need_query_property ctx, 'goal_id'
    return
  [proposed_goals, db] = await get_proposed_goals()
  await n2p -> proposed_goals.update({_id: mongodb.ObjectID(goal_id)}, {$inc: {upvotes: 1}}, it)
  ctx.body = JSON.stringify {response: 'done', success: true}
  db?close()

app.get '/downvote_proposed_goal', (ctx) ->>
  ctx.type = 'json'
  {goal_id} = ctx.request.query
  if need_query_property ctx, 'goal_id'
    return
  [proposed_goals, db] = await get_proposed_goals()
  await n2p -> proposed_goals.update({_id: mongodb.ObjectID(goal_id)}, {$inc: {downvotes: 1}}, it)
  ctx.body = JSON.stringify {response: 'done', success: true}
  db?close()
