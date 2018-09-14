const {
  app,
  auth,
  memoizeSingleAsync,
  get_mongo_db,
  get_collection,
  get_signups,
  get_secrets,
  get_logging_states,
  get_installs,
  get_uninstalls,
  get_uninstall_feedback,
  list_collections,
  list_log_collections_for_user,
  list_intervention_collections_for_user,
  list_log_collections_for_logname,
  get_collection_for_user_and_logname,
  get_user_active_dates,
  need_query_property,
  need_query_properties,
  expose_get_auth,
  get_collection_site_ideas,
  get_install_active_dates,
  get_intervention_votes,
  get_intervention_votes_total
} = require('libs/server_common')

const n2p = require('n2p')
const moment = require('moment')
const semver = require('semver')
const prelude = require('prelude-ls')

app.get('/viewdata_routes_js', auth, async function(ctx) {
  ctx.body = 'hello world from viewdata_routes_js'
  return
})

async function get_collection_items(collection_name) {
  const [collection, db] = await get_collection(collection_name)
  let items = await n2p(function(cb) {
    collection.find({}).toArray(cb)
  })
  if (db != null) {
    db.close()
  }
  return items
}

async function get_collection_for_user(userid, collection_name) {
  return await get_collection_items(userid + '_' + collection_name)
  //return await getjson('/printcollection', {userid: userid, logname: collection_name})
}

const get_collection_for_user_cached = get_collection_for_user

async function get_session_info_list_for_user(userid) {
  let output = []
  let interventions_active_for_domain_and_session = await get_collection_for_user_cached(userid, 'synced:interventions_active_for_domain_and_session')
  let domain_to_session_id_to_time_spent = await get_domain_to_session_id_to_time_spent(userid)
  let last_active_date_for_userid = await list_last_active_date_for_user(userid)
  for (let item of interventions_active_for_domain_and_session) {
    let session_id = item.key2
    let domain = item.key
    let userid_inlog = item.userid
    let interventions_active = JSON.parse(item.val)
    let intervention = interventions_active[0]
    let a = JSON.stringify(intervention)
    console.log(a)
    let timestamp = item.timestamp
    let timestamp_local = item.timestamp_local
    let install_id = item.install_id
    let last_active_date_for_install_id = await list_last_active_date_for_install_id(install_id)
    if (userid_inlog != userid) {
      console.log('mismatch between userid and userid_inlog for userid ' + userid)
      continue
    }
    if (domain_to_session_id_to_time_spent[domain] == null || domain_to_session_id_to_time_spent[domain][session_id] == null) {
      //console.log('warning: missing session duration for session id ' + session_id + ' on domain ' + domain)
      continue
    }
    let time_spent = domain_to_session_id_to_time_spent[domain][session_id]
    output.push({
      last_active_epoch_for_userid: convert_date_to_epoch(last_active_date_for_userid),
      last_active_epoch_for_install_id: convert_date_to_epoch(last_active_date_for_install_id),
      last_active_date_for_userid,
      last_active_date_for_install_id,
      time_spent,
      session_id,
      domain,
      interventions_active,
      intervention,
      timestamp,
      timestamp_local,
      install_id,
      userid,
    })
  }
  return output
}

expose_get_auth(get_session_info_list_for_user, 'userid')

async function get_domain_to_session_id_to_time_spent(userid) {
  let seconds_on_domain_per_session = await get_collection_for_user_cached(userid, 'synced:seconds_on_domain_per_session')
  let domain_to_session_id_to_time_spent = {}
  for (let item of seconds_on_domain_per_session) {
    let domain = item.key
    let session_id = item.key2
    let seconds_spent = item.val
    if (domain_to_session_id_to_time_spent[domain] == null) {
      domain_to_session_id_to_time_spent[domain] = {}
    }
    if (domain_to_session_id_to_time_spent[domain][session_id] == null) {
      domain_to_session_id_to_time_spent[domain][session_id] = seconds_spent
    } else {
      domain_to_session_id_to_time_spent[domain][session_id] = Math.max(seconds_spent, domain_to_session_id_to_time_spent[domain][session_id])
    }
  }
  return domain_to_session_id_to_time_spent
}

async function list_last_active_date_for_user(userid) {
  let user_to_dates_active = await get_user_to_dates_active_cached()
  let dates_active = user_to_dates_active[userid]
  if (dates_active == null) {
    return null
  }
  return dates_active[dates_active.length - 1]
}

async function list_last_active_date_for_install_id(install_id) {
  let install_id_to_dates_active = await get_install_id_to_dates_active_cached()
  let dates_active = install_id_to_dates_active[install_id]
  if (dates_active == null) {
    return null
  }
  return dates_active[0]
}

function convert_date_to_epoch(date) {
  if (date == null) {
    return null
  }
  let start_of_epoch = moment().year(2016).month(0).date(1).hours(0).minutes(0).seconds(0).milliseconds(0)
  let year = parseInt(date.substr(0, 4))
  let month = parseInt(date.substr(4, 2)) - 1
  let day = parseInt(date.substr(6, 2))
  let date_moment = moment().year(year).month(month).date(day).hours(0).minutes(0).seconds(0).milliseconds(0)
  return date_moment.diff(start_of_epoch, 'days')
}


const get_user_to_dates_active_cached = memoizeSingleAsync(async function() {
  return await viewdata.get_user_to_dates_active()
})

const get_install_id_to_dates_active_cached = memoizeSingleAsync(async function() {
  return await viewdata.get_install_id_to_dates_active()
})

const viewdata = require('routes/viewdata_routes')

require('libs/globals').add_globals(module.exports)
