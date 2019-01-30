require! {
  mongodb
  getsecret
  fs
  n2p
}

local_cache_db = null
getdb_running = false

mongourl = getsecret('MONGODB_URI_VOTING')

export get_mongo_db = ->>
  if local_cache_db?
    return local_cache_db
  if getdb_running
    while getdb_running
      await sleep(1)
    while getdb_running or local_cache_db == null
      await sleep(1)
    return local_cache_db
  getdb_running := true
  try
    local_cache_db := await n2p -> mongodb.MongoClient.connect(
      mongourl,
      {},
      it
    )
    return local_cache_db
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

export get_collection = (collection_name) ->>
  db = await get_mongo_db()
  return db.collection(collection_name)

export get_collection_goal_ideas = ->>
  return await get_collection('get_collection_goal_ideas')

export get_collection_goal_idea_logs = ->>
  return await get_collection('get_collection_goal_idea_logs')

export get_collection_goal_idea_candidates = ->>
  return await get_collection('get_collection_goal_idea_candidates')

sleep = (time) ->>
  return new Promise ->
    setTimeout(it, time)

keep_trying = (fn) ->>
  succeeded = false
  while not succeeded
    try
      output = await n2p(fn)
      succeeded = true
    catch error
      console.log error
      await sleep(12000)
  return output

export post_idea = (goal, idea) ->>
  ideas = await get_collection_goal_ideas()
  existing_ideas = await keep_trying -> ideas.find({goal, idea}).toArray(it)
  console.log 'existing ideas'
  console.log existing_ideas
  if existing_ideas.length > 0
    return
  await keep_trying -> ideas.insert({goal, idea, vote: 0, lostvote: 0, tie: 0}, it)
  return

goal_to_ideas = {
  'facebook/spend_less_time': [
    # new ideas
    'Remove the unread notifications icon'
    'Notify you of the average time users spend on the website'
    # existing nudges
    'Injects timer into the Facebook feed'
    'Removes the Facebook news feed'
    'Notifies you of time spent in the corner of your desktop'
    'Removes Facebook comments'
    'Removes clickbait'
    'Notifies you of time spent every minute'
    'Shows time spent on site at the top of screen'
    'Freezes scrolling after a certain amount of scrolls'
    'Show time spent and visit count each visit'
    'Makes you wait a few seconds before visiting'
    'Closes tab after 60 seconds'
    'Asks how long you want to spend on site this visit'
    'Asks what you aim to do this visit and puts a reminder up'
  ],
  'youtube/spend_less_time': [
    # new ideas
    'Notify you of the average time users spend on the website'
     # existing nudges
    'Notifies you of time spent in the corner of your desktop'
    'Removes Youtube comments'
    'Shows time spent on site at the top of screen'
    'Freezes scrolling after a certain amount of scrolls'
    'Show time spent and visit count each visit'
    'Makes you wait a few seconds before visiting'
    'Closes tab after 60 seconds'
    'Asks how long you want to spend on site this visit'
    'Asks what you aim to do this visit and puts a reminder up'

  ],
  "generic/spend_less_time": [
    "Set an alarm: \"How long do you want to spend on Facebook on this visit?\"", 
    "Display \"Why are you visiting Facebook today?\" and response space.", 
    "Set an alarm: \"How long do you want to spend on Facebook?\"", 
    "Display \"Make a detailed plan for spending less time online.\"", 
    "Display \"[#] days of exiting Facebook in goal time!\" and insert link to resetting goal time.", 
    "Display \"You've spent [#] minutes on Facebook today. That's [#] minutes over your goal!\"", 
    "Display \"[#] days of meeting all your goals!\" and insert link to resetting goal time.", 
    "Display \"Make a commitment for how much time you will spend online.\"", 
    "Display \"Recommendation: try to pay attention to the way other people save time online!\"", 
    "Display \"[#] days of exiting Facebook within 10 minutes each visit!\"", 
    "Display \"Recommendation: record how you use your time online on a calendar\"", 
    "Display \"Your friend [name] has saved [#] minutes online today\"", 
    "Display \"You have save [#] minutes since turning on the \"No Clickbait\" nudge/asking a friend to monitor your online use.\"", 
    "Display \"Recommendation: call a friend when you feel the urge to spend time online.\"", 
    "Display \"Recommendation: encourage a friend to monitor your online use\"", 
    "https://myfastpc-4b43.kxcdn.com/wp-content/uploads/clickbait-1.webp", 
    "Display \"Insight: You tend to [action] before using Facebook.\"", 
    "Display \"Why do you think you spend time online?\" After response, display \"Do you think you might also be using it to socialize with others?\"", 
    "Display \"Recommendation: pay attention to what helps you avoid clickbait material\"", 
    "Display \"Did you know: mental health is often negatively affected by excessive online use.\"", 
    "Open https://www.youtube.com/watch?v=Qvcx7Y4caQE", 
    "Display \"Great! You have saved [#] minutes online today. How do you feel?\"", 
    "Display \"Are you sure you want to continue? Think about how much you will regret this.\"", 
    "Display \"Did you know: spending less time online increases happiness and life satisfaction.\"", 
    "Pop up image: http://www.extremetech.com/wp-content/uploads/2014/10/windows-10-new-close-animation.gif", 
    "Display \"[#] other users are saving time with HabitLab\"", 
    "Display \"Keep in mind: people who use Facebook less tend to be seen as  more productive!\"", 
    "Display \"Reminder: you have made a commitment to saving time online!\"", 
    "Hides number of likes and comments on posts", 
    "Disable the \"stop autoplay\"/\"disable comments\" function", 
    "Display \"Spend the next 5 hours on Facebook!\"", 
    "Starting from 8am on a day, the first time user tries to access site, they will be asked \"When would be a good time for you to close all social media windows? Select from below.\". And user will be able to select from options \"1 hour from now\", \"2 hours from now\", \"4 hours from now\".", 
    "Redirect to Trump's Twitter page on load and after enough time spent/Give the website ugly fonts and colors", 
    "Display \"Not using Facebook? Close this tab!\"", 
    "After 10 videos on Youtube, display pop-up link to https://www.realsimple.com/work-life/entertainment/summer-activities", 
    "Display \"Recommendation: close Facebook before you start studying!\"", 
    "Display \"How about using Google Scholar instead of Youtube?\"", 
    "Block online for an entire day after goal not met the previous day", 
    "Display \"Recommendation: try to use your healthy Facebook habits on Youtube!\"", 
    "Gradually decrease time allowed on sites before blocking them (show time monitor on top of screen indicating how much time is left).", 
    "Before directing user to site or during the site visit, show video of doctor/inspirational figure emphsizing the importance of reducing time online.", 
    "Before directing user to site, display screen that says \"What are some pros and cons for spending time on X_site?\" and then have two columns marked as \"Pros\" and \"Cons\" respectively. Under the \"Pros\" column the user is provided 1 entry to fill out while under the \"Cons\" column the user is provided 3 entries to fill out. ", 
    "Before directing user to site, display screen that says \"What's going to happen if you binge using X_site? What's going to happen if you spend less time on X_site?\" and then have two text boxes pre-filled with \"I will\" ... \"if I binge using X_site\", and \"I will\" ... \"if I spend less time on X_site\". Give blank lines for the \"...\" area for user to fill out. ", 
    "Every day the user has met their time saving goal, add a badge to their account. Display the badge increase message \"You met your time saving goal yesterday! Now you have one more badge in your account! Total # of badges: X.\" the next day the user accesses site. ", 
    "Every day the user has met their time saving goal, display congratulation message that says \"Hoorayyy! You've met your goal of saving X amount of time today. Congratulations! Keep you the good work!\"", 
    "Before and during site visit, display pop-up text that says \"Please remember that for each day you meet your time saving goal you will see a beautiful congratulation message by HabitLab and all its users!\" ", 
    "When user clicks the exit/close button to leave site, display message that says \" You will be rewarded with a nudge free visit if you don't come back within the next 8 hours!\"", 
    "Each time the user meets their time saving goal, display message that says \"Woohoo! You've met your time saving goal. Go get yourself a snack! You deserve a treat!\" ", 
    "Each time the user meets their time saving goal, display message that says \"Woohoo! You've met your time saving goal. Go get yourself a snack! You deserve a treat!\" ", 
    "Give user a nudge free day if they have met their time saving goals", 
    "Display message that says \" This site will be blocked for 12 hours if you continue to binge using it and break our \"time spent\" contract!\"", 
    "Display message that says \"You know what? You could use Yoga/some tea/meditation to reduce your urge to spend time online!\"", 
    "Display message \"You usually spend an hour per visit on X_site. Now let's spice it up and spend 2 hours.\"", 
    "Causes buttons and options to occasionally jump away from the mouse", 
    "After a long time spent on X_site, display message that says \"You've spent quite a while on X_site. Can you reduce the amount of time spent with friends who spend a lot of time on X_site?\"", 
    "Disable autoplay on videos/Remove clickbait/Remove sidebar links/Remove comment section", 
    "Ask user to make a to-do list (entries where user can input text) before directing user to site, and display that list during the site visit. Every 10 minutes display a pop-up window that asks user \"Do you want to work on things on your to-do list now?\"", 
    "Add interesting, floating \"clouds\" on the screen suggesting exiting site and working on something else", 
    "Display message that says \"Use HabitLab to save time online and set a good example for other users that are also trying to improve their online habits!\"", 
    "Display message that says \"Think of how spending more time here can hurt your productivity and your relationships in life.\"", 
    "Display screen that says \"You missed your goal of saving X hours a week online. Do you value moderation and self-control?\" and a check box where the user can only check Yes.", 
    "Display \"What are some of your personal strengths\" before visiting site. User must input at least one personal strength before being directed to site. ", 
    "Display \"Hey! Ex-YouTube Fan! You probably don't want to waste time on YouTube again!\" ", 
    "If user spends more than 15 minutes on Facebook for a visit, disallow access to Facebook within the next 2 hours. If user tries to Open Facebook in the meantime, display message that says \"Sorry, but you spent more than 15 minutes here during your last visit. You can visit again in X minutes.\"", 
    "Show user ugly screen color and font if they spend more than 15 minutes on site", 
    "Make the video blurry/silent if user spends more than 15 minutes on YouTube", 
    "Reward user with a badge/sticker for any reduction in time spent on site each day, gradually requiring the daily time spent on site to be closer to the ideal daily time spent  ", 
    "Reward user with a badge for exiting Youtube before watching more than 5 videos, then reward contingent on not clicking recommended videos, and then reward coningent on not opening YouTube for a certain amount of time", 
    "If within a day (24 hours) the user only used site during lunch break/dinner break/before bed times but not during work hours, then the next day when they first try to access site, display congratulations message and reward them with a badge/sticker", 
    "Reward user with a badge/sticker for consumption of non-clickbait videos but not consumption of clickbait videos", 
    "Give user a short funny video/meme to watch or song to listen to the first time they access site after 24 hours, if they had used less than X amount of time on site for the past 24 hours.", 
    "Give user a badge for every hour without using site, then every 3 hours, every 6 hours, and so on. Display message will be \"You've earned a badge by staying away from X_site for Y hours!\"", 
    "Once the user has continuously reached the time saving goal for a week, display screen that says \"Congratulations! You've met your time saving goals a week in a row! Here's a nudge-free visit. Keep up the good work!\".", 
    "During the middle of the site visit, display message that says \"Even though you spent more than 20 minutes last time you were here, we believe that you can spend less than 20 minutes this time!\"", 
    "Display message that says \"Please imagine being in front of your laptop and enjoying doing work instead.\"", 
    "After user finishes one video, display screen that says \"Can you think about an occasion where you had chosen not to continue watching the next video and close YouTube?\"", 
    "Before and 15 minutes into site visit, display screen that says \"I'm going to feel better if I take a nap/do work now instead\".", 
    "Before directing user to site, display screen that says \"Now imagine how tired and unproductive you would be if you keep spending time here\". User can choose to exit from site at that point or close the text screen.", 
    "Before directing user to site, display screen that says \"Now imagine how much more productive you would be if you choose not use X_site instead\". User can choose to exit from site at that point or close the text screen.", 
    "After user's third video, display window that shows statistics of how much time one can save if they exit YouTube before watching the 4th video"
  ]
}

initialize = ->>
  for goal in Object.keys(goal_to_ideas)
    ideas = goal_to_ideas[goal]
    console.log ideas
    for idea in ideas
      await post_idea goal, idea
  return

clearvotes = ->>
  ideas = await get_collection_goal_ideas()
  await keep_trying -> ideas.updateMany({}, {$set: {vote: 0, lostvote: 0, tie: 0}}, it)
  return

clearvotelogs = ->>
  votelogs = await get_collection_goal_idea_logs()
  await votelogs.remove({})
  return

clearideas = ->>
  ideas = await get_collection_goal_ideas()
  await ideas.remove({})
  return

clearideacandidates = ->>
  candidates = await get_collection_goal_idea_candidates()
  await candidates.remove({})
  return

do ->>
  argv = require('yargs')
  .option('initialize', {
    describe: 'post initial set of ideas'
    default: false
  })
  .option('clearvotes', {
    describe: 'resets the existing set of votes'
    default: false
  })
  .option('clearvotelogs', {
    describe: 'clears the existing set of vote logs'
    default: false
  })
  .option('clearideas', {
    describe: 'clears the existing set of ideas'
    default: false
  })
  .option('clearideacandidates', {
    describe: 'clears the existing set of idea candidates'
    default: false
  })
  #.option('fresh', {
  #  describe: 'perform a fresh sync (deleting the listcio )'
  #})
  .strict()
  .argv
  if argv.initialize
    await initialize()
  else if argv.clearvotes
    await clearvotes()
  else if argv.clearvotelogs
    await clearvotelogs()
  else if argv.clearideas
    await clearideas()
  else if argv.clearideacandidates
    await clearideacandidates()
  else
    console.log('no command was provided')
  process.exit()
