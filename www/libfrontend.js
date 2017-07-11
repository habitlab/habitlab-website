async function geolocate_ip(ip_addr) {
  let geolocate_info = {}
  if (localStorage.getItem('geolocate_info_' + ip_addr)) {
    geolocate_info = JSON.parse(localStorage.getItem('geolocate_info_' + ip_addr))
  } else {
    geolocate_info = await $.ajax({
      url: 'http://ip-api.com/json/' + ip_addr,
      jsonp: 'callback',
      dataType: 'jsonp'
    })
    localStorage.setItem('geolocate_info_' + ip_addr, JSON.stringify(geolocate_info))
  }
  return geolocate_info
}

function display_dictionary_as_table(dict, selector) {
  let keys_and_values = []
  for (let key of Object.keys(dict)) {
    let value = dict[key]
    keys_and_values.push([key, value])
  }
  keys_and_values.sort(function(a, b) {
    return a[1] - b[1]
  })
  keys_and_values.reverse()
  for (let [key,val] of keys_and_values) {
    $(selector).append($('<div>').text(key + ': ' + val))
  }
}

function display_list_as_table(list, selector) {
  target = $(selector)
  for (let item of list) {
    target.append($('<div>').text(JSON.stringify(item)))
  }
}

function dict_to_sorted(language_to_num_installs) {
  let language_and_num_installs = []
  for (let language of Object.keys(language_to_num_installs)) {
    let num_installs = language_to_num_installs[language]
    language_and_num_installs.push([language, num_installs])
  }
  language_and_num_installs.sort((a, b) => a[1] - b[1]).reverse()
  return language_and_num_installs
}

function dict_to_array_sorted_zeros(install_duration_to_num_users) {
  let max_value = prelude.maximum(Object.keys(install_duration_to_num_users).map(x => parseInt(x)))
  let output = new Array(max_value + 1).fill(0)
  for (let i = 0; i <= max_value; ++i) {
    if (install_duration_to_num_users[(i).toString()] == null) {
      output[i] = [(i).toString(), 0]
    } else {
      output[i] = [(i).toString(), install_duration_to_num_users[i]]
    }
  }
  return output
}

async function getjson(path, data) {
  if (typeof(data) != 'object') {
    data = {}
  }
  let querystring = ''
  let is_first = true
  for (let key of Object.keys(data)) {
    if (is_first) {
      is_first = false
      querystring += '?' + key + '=' + data[key]
    } else {
      querystring += '&' + key + '=' + data[key]
    }
  }
  return await fetch(path + querystring).then(x => x.json())
}

async function get_install_data() {
  let install_info_list = await fetch('/get_installs').then(x => x.json())
  let output = []
   for (let install_info of install_info_list) {
    if (install_info.devmode || install_info.unofficial_version) {
      continue
    }
    if (!install_info.language || !install_info.languages) {
      continue
    }
    if (!install_info.install_source) {
      continue
    }
    output.push(install_info)
  }
  return output
}

async function get_uninstall_data() {
  let install_info_list = await getjson('/get_uninstalls')
  let output = []
  for (let install_info of install_info_list) {
    if (install_info.r != 0) { // not stable release
      continue
    }
    //if (!install_info.language || !install_info.languages) {
    //  continue
    //}
    output.push(install_info)
  }
  return output
}

async function get_logging_states() {
  let logging_info_list = await getjson('/get_logging_states')
  return logging_info_list
}

async function list_active_users() {
  let active_users_list = await getjson('/getactiveusers')
  return active_users_list
}

async function list_active_users_week() {
  let active_users_list = await getjson('/getactiveusers_week')
  return active_users_list
}

async function get_user_to_install_times() {
  let user_to_install_times = await getjson('/get_user_to_install_times')
  return user_to_install_times
}

async function get_user_to_uninstall_times() {
  let user_to_uninstall_times = await getjson('/get_user_to_uninstall_times')
  return user_to_uninstall_times
}

async function get_collection_for_user(userid, collection_name) {
  return await getjson('/printcollection', {userid: userid, logname: collection_name})
}

async function get_latest_goal_info_for_user(userid) {
  let goal_logs = await get_collection_for_user(userid, 'logs:goals')
  let latest_timestamp = 0
  let latest_log_info = {}
  for (let log_info of goal_logs) {
    let timestamp = log_info.timestamp
    if (timestamp > latest_timestamp) {
      latest_timestamp = timestamp
      latest_log_info = log_info
    }
  }
  return latest_log_info
}

async function get_latest_intervention_info_for_user(userid) {
  let intervention_logs = await get_collection_for_user(userid, 'logs:interventions')
  let latest_timestamp = 0
  let latest_log_info = {}
  for (let log_info of intervention_logs) {
    let timestamp = log_info.timestamp
    if (timestamp > latest_timestamp) {
      latest_timestamp = timestamp
      latest_log_info = log_info
    }
  }
  return latest_log_info
}

async function get_enabled_goals_for_user(userid) {
  let latest_log_info = await get_latest_goal_info_for_user(userid)
  let output = []
  if (latest_log_info.enabled_goals) {
    for (let goal_name of Object.keys(latest_log_info.enabled_goals)) {
      if (latest_log_info.enabled_goals[goal_name]) {
        output.push(goal_name)
      }
    }
  }
  output.sort()
  return output
}

async function get_goals_tried_by_user(userid) {
  let goal_targets_logs = await get_collection_for_user(userid, 'synced:goal_targets')
  let output_set = {}
  for (let goal_target_info of goal_targets_logs) {
    let goal_name = goal_target_info.key
    output_set[goal_name] = true
  }
  let output = Object.keys(output_set)
  output.sort()
  return output
}

async function get_goal_targets_for_user(userid) {
  let goal_targets_logs = await get_collection_for_user(userid, 'synced:goal_targets')
  let output = {}
  for (let goal_target_info of goal_targets_logs) {
    let goal_name = goal_target_info.key
    let goal_target = goal_target_info.val
    output[goal_name] = goal_target
  }
  return output
}

/*
async function get_enabled_interventions_for_user(userid) {
  let latest_log_info = await get_latest_goal_info_for_user(userid)
  let output = []
  if (latest_log_info.enabled_interventions) {
    for (let intervention_name of Object.keys(latest_log_info.enabled_interventions)) {
      if (latest_log_info.enabled_interventions[intervention_name]) {
        output.push(intervention_name)
      }
    }
  }
  output.sort()
  return output
}
*/

async function get_enabled_interventions_for_user(userid) {
  let latest_log_info = await get_latest_intervention_info_for_user(userid)
  let output = {}
  if (latest_log_info && latest_log_info.enabled_interventions) {
    return latest_log_info.enabled_interventions
  }
  return output
}

async function get_disabled_interventions_for_user(userid) {
  let results = await get_collection_for_user(user_id, 'synced:interventions_currently_disabled')
  let output = {}
  for (let info of results) {
    let name = info.key
    if (info.val == true) {
      output[name] = true
    } else if (info.val == false) {
      output[name] = false
    }
  }
  return output
}

async function get_enabled_goals_for_user(userid) {
  let latest_log_info = await get_latest_intervention_info_for_user(userid)
  let output = {}
  if (latest_log_info && latest_log_info.enabled_goals) {
    return latest_log_info.enabled_goals
  }
  return output
}

async function list_intervention_logs_for_user(userid) {
  let all_logs = await getjson('/list_logs_for_user' , {userid: userid})
  let output = []
  for (let log_name of all_logs) {
    let base_log_name = log_name.replace(userid + '_', '')
    output.push(base_log_name)
  }
  return output
}

//async function get_intervention_to_num_impressions_for_user(userid) {
  //let interventions_with_data = await get_
//}

async function get_last_interventions_and_num_impressions_for_former_users() {
  let intervention_to_num_last = {}
  let intervention_to_total_impressions = {}
  let former_users = await get_users_with_logs_who_are_no_longer_active()
  for (let user_id of former_users) {
    let last_intervention = await get_last_intervention_seen(user_id)
    let intervention_to_num_impressions = await get_intervention_to_num_times_seen(user_id)
    for (let intervention_name of Object.keys(intervention_to_num_impressions)) {
      if (intervention_to_total_impressions[intervention_name] == null) {
        intervention_to_total_impressions[intervention_name] = 0
      }
      intervention_to_total_impressions[intervention_name] += intervention_to_num_impressions[intervention_name]
    }
    if (intervention_to_num_last[last_intervention] == null) {
      intervention_to_num_last[last_intervention] = 1
    } else {
      intervention_to_num_last[last_intervention] += 1
    }
  }
  let output = {}
  for (let intervention_name of Object.keys(intervention_to_total_impressions)) {
    let num_last = intervention_to_num_last[intervention_name]
    if (num_last == null) {
      num_last = 0
    }
    let total_impressions = intervention_to_total_impressions[intervention_name]
    let uninstall_fraction = num_last / total_impressions
    output[intervention_name] = {
      num_last: num_last,
      total_impressions: total_impressions,
      uninstall_fraction: uninstall_fraction
    }
  }
  return output
}

function expose_getjson(func_name, ...params) {
  let func_body = null
  let request_path = '/' + func_name
  window[func_name] = async function(...args) {
    let data = {}
    for (let i = 0; i < params.length; ++i) {
      let param = params[i]
      let value = args[i]
      data[param] = value
    }
    return await getjson(request_path, data)
  }
}

expose_getjson('get_time_last_log_was_sent_for_user', 'userid')

expose_getjson('get_last_intervention_seen_and_time', 'userid')

expose_getjson('get_last_intervention_seen', 'userid')

expose_getjson('list_logs_for_user', 'userid')

expose_getjson('get_dates_active_for_user', 'userid')

expose_getjson('get_is_logging_enabled_for_user', 'userid')

expose_getjson('get_user_to_is_logging_enabled')

expose_getjson('get_intervention_to_num_times_seen', 'userid')

expose_getjson('get_users_with_logs_who_are_no_longer_active')

expose_getjson('get_last_interventions_for_former_users')

function printcb(err, result) {
  console.log(err)
  if (result !== undefined) {
    console.log(result)
  }
}
