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
  let output = new Array(max_value).fill(0)
  for (let i = 0; i < max_value; ++i) {
    if (install_duration_to_num_users[(i).toString()] == null) {
      output[i] = [(i).toString(), 0]
    } else {
      output[i] = [(i).toString(), install_duration_to_num_users[i]]
    }
  }
  return output
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
  let install_info_list = await fetch('/get_uninstalls').then(x => x.json())
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
  let logging_info_list = await fetch('/get_logging_states').then(x => x.json())
  return logging_info_list
}

async function list_active_users() {
  let active_users_list = await fetch('/getactiveusers').then(x => x.json())
  return active_users_list
}

async function get_user_to_install_times() {
  let user_to_install_times = await fetch('/get_user_to_install_times').then(x => x.json())
  return user_to_install_times
}

async function get_user_to_uninstall_times() {
  let user_to_uninstall_times = await fetch('/get_user_to_uninstall_times').then(x => x.json())
  return user_to_uninstall_times
}
