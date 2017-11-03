{
  app
  get_proposed_goals
  mongodb
  need_query_properties
  need_query_property
  get_intervention_votes
  get_intervention_votes_total
} = require 'libs/server_common'

require! {
  n2p
}
//Interventions for testing//
all_contributed_interventions = [
  {
    "name": "block_gif_links",
    "website":"www.reddit.com"
    "goal": "spend_less_time",
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
    "name": "remove_comments",
    "goal": "spend_less_time",
    "website":"www.reddit.com"
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
  if need_query_properties ctx, ['name', 'goal','website', 'description']
    return
  numusers ?= 0
  stars ?= 0
  comments ?= []
  new_contributed_intervention = {
    name
    goal
    website
    description
    numusers
    stars
    comments
  }
  [contributed_interventions, db] = await get_contributed_interventions()
  result = await n2p -> contributed_interventions.insert(new_contributed_intervention, it)
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
  [contributed_interventions, db] = await get_contributed_interventions()//Find these functions//
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

export upvote_intervention = (intervention_name, userid) ->>
  [intervention_votes, db] = await get_intervention_votes()
  [intervention_votes_total, db2] = await get_intervention_votes_total()
  await n2p -> intervention_votes.update({intervention_name, userid}, {$inc: {upvotes: 1}}, {upsert: true}, it)
  await n2p -> intervention_votes_total.update({intervention_name}, {$inc: {upvotes: 1}}, {upsert: true}, it)
  db.close()
  db2.close()
  return

/*
app.get '/upvote_intervention', (ctx) ->>
  {intervention_name, userid} = ctx.request.query
  if need_query_properties ctx, ['intervention_name', 'user_id']
    return
  await upvote_intervention(intervention_name, userid)
  return

app.get '/downvote_intervention', (ctx) ->>
  {intervention_name, userid} = ctx.request.query
  if need_query_properties ctx, ['intervention_name', 'user_id']
    return
  intervention_downvotes = await get_intervention_votes()
  intervention_downvotes_total = await get_intervention_votes_total()
  return
*/

export clear_intervention_upvotes_total = ->>
  [intervention_votes_total, db] = await get_intervention_votes_total()
  intervention_votes_total.deleteMany()
  db.close()
  return

export get_intervention_upvotes_total = (intervention_name) ->>
  [intervention_votes_total, db] = await get_intervention_votes_total()
  results = await n2p -> intervention_votes_total.find({intervention_name}).toArray(it)
  db.close()
  if results.length < 1
    return 0
  if not results[0].upvotes?
    return 0
  return results[0].upvotes

/*
app.get '/get_intervention_upvotes', (ctx) ->>
  {intervention_name} = ctx.request.query
  ctx.body = 0

app.get '/get_intervention_downvotes', (ctx) ->>
  {intervention_name} = ctx.request.query
  ctx.body = 0
*/

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

require('libs/globals').add_globals(module.exports)
