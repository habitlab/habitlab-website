{
  app
  get_collection
  get_signups
  get_secrets
  get_logging_states
  get_installs
  get_uninstalls
  get_uninstall_feedback
  get_proposed_goals
  list_collections
  list_log_collections_for_user
  list_log_collections_for_logname
  get_collection_for_user_and_logname
  mongodb
} = require 'libs/server_common'

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

app.get '/get_contributed_interventions_for_goal', ->*
  this.type = 'json'
  {goal} = this.request.query
  interventions_list = goal_name_to_interventions[goal] ? []
  intervention_info_list = [intervention_name_to_data[x] for x in interventions_list]
  this.body = JSON.stringify intervention_info_list

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

app.get '/get_proposed_goals', ->*
  this.type = 'json'
  # [proposed_goals, db] = yield 
  this.body = JSON.stringify proposed_goals_list

app.get '/upvote_proposed_goal', ->*
  this.type = 'json'
  {goal_id} = this.request.query
  if not goal_id?
    this.body = JSON.stringify {response: 'error', error: 'Need goal_id'}
    return
  proposed_goals_list[goal_id].upvotes += 1
  this.body = JSON.stringify {response: 'done', success: true}

app.get '/downvote_proposed_goal', ->*
  this.type = 'json'
  {goal_id} = this.request.query
  if not goal_id?
    this.body = JSON.stringify {response: 'error', error: 'Need goal_id'}
    return
  proposed_goals_list[goal_id].downvotes += 1
  this.body = JSON.stringify {response: 'done', success: true}
