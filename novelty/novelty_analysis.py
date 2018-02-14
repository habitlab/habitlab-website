import numpy as np
import json
import datetime
import matplotlib.pyplot as plt

def temporary_disablement():
  uninstalled = [0, 0, 0, 8, 7, 0, 0, 0, 1, 0, 0, 0]
  not_uninstalled = [4,14,11,0,0,3,0,0,0,9,0,0,0,1,0,10,4,0,7,0,2,9,0,0,0,2,0,0,0,2,0,0,0,0,6,9,2,0,0,0,0,0,9,0,0,1,1,0,0,0,0,0,0,1,4,0,4,2,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,3,4,4,0,0,0,0,6,5,2,0,0,3,0,1,0,0,0,0,0,0,2,0,0,6,0,4,0,0,0,0,0,0,0,0,0,12,0,0,1,0,0,1,3,6,0,0,0,1,0,0,3,2,0,2,0,0,2,0,0,0,1,5,0,9,3,0,4,0,8,0,3,0,0,1,0,0,0,1,0,2,0,3,17,0,1,0,0,0,0,1,3,0,0,3,0,14,0,4,10,0,0,0,0,0,0,11,8,0,0,14,8,4,0,17,0,0,0,0,6,19,1,0,0,13,0,0,3,0,0,0,0,12,0,1,0,0,0,0,4,1,1,0,3,7,0,0,0,1,0,0,0,3,0,0,0,0,10,0,0,0,0,0,0,1,107,9,4,0,0,0,0,0,5,1,2,0,1,10,0,0,3,147,8,1,7,0,0,3,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,307,0,7,0,4,0,0,11,5,0,0,3,0,0,0,0,0,0,1,26,3,21,0,0,2,0,0,0,4,0,0,0,1,0,0,0,0,0,0,0,0,0,0,2,0,6,4,0,3,0,6,0,0,0,0,0,1,0,0,0,0,11,0,2,0,1,16,0,0,0,0,7,0,0,1,13,4,4,0,0,0,0,6]
  
  # plt.hist(uninstalled)
  # plt.title("Number of Intervention Log Records for Uninstalled Users")
  # plt.show()

  plt.hist(not_uninstalled, bins=np.arange(40))
  plt.title("Number of Intervention Log Records for Non-Uninstalled Users")
  plt.show()

# given the intervention log as dictionary, returns a list of relative days since
# the intervention first appeared and the list of the nth times the intervention 
# has appeared
def calibrate_instance(interv_log):
  days = []
  nth = []
  first_day = int(interv_log[0]['day'])
  for i in range(len(interv_log)):
    days.append(int(interv_log[i]['day']) - first_day)
    nth.append(i)
  print days, nth

def day_vs_session_len():
  return

def main():
  youtube_remove_comment = '[{"_id":"5a26c4ef9064e20011fcc594","url":"https://www.youtube.com/redirect?redir_token=s1D8BuujbTGAo7qmCYjjwpA2lKt8MTUxMDIwNTcyNUAxNTEwMTE5MzI1&q=https%3A%2F%2Fgithub.com%2FGameye98%2FLazymux&event=video_description&v=mwVE1_1_DaA","type":"impression","intervention":"youtube/remove_comment_section","userid":"ba656c5622d547659efe36f9","day":704,"synced":0,"timestamp":1512490223901,"localtime":"Tue Dec 05 2017 16:07:11 GMT+0000 (GMT Standard Time)","itemid":"1b92d199a173fed1ae7757a0","log_major_ver":"8","log_minor_ver":"1","habitlab_version":"1.0.187","id":1,"logname":"youtube/remove_comment_section","timestamp_local":1512490031861},{"_id":"5a26c62a9064e20011fcc613","url":"https://www.youtube.com/watch?v=mqGc5478PYQ","type":"impression","intervention":"youtube/remove_comment_section","userid":"ba656c5622d547659efe36f9","day":704,"synced":0,"timestamp":1512490538591,"localtime":"Tue Dec 05 2017 16:12:27 GMT+0000 (GMT Standard Time)","itemid":"d60d29bec3edfe44d6b9c4aa","log_major_ver":"8","log_minor_ver":"1","habitlab_version":"1.0.187","id":2,"logname":"youtube/remove_comment_section","timestamp_local":1512490347203},{"_id":"5a4cd75b8d97e600116add89","url":"https://www.youtube.com/watch?v=P0HBfn9n1wo","type":"impression","intervention":"youtube/remove_comment_section","userid":"ba656c5622d547659efe36f9","day":733,"synced":0,"timestamp":1514985307898,"localtime":"Wed Jan 03 2018 13:11:02 GMT+0000 (GMT Standard Time)","itemid":"81b0cc8c054681009af36f6c","log_major_ver":"8","log_minor_ver":"1","habitlab_version":"1.0.187","id":3,"logname":"youtube/remove_comment_section","timestamp_local":1514985062739},{"_id":"5a572be8c0c20e00118b4ff4","url":"https://www.youtube.com/","type":"impression","intervention":"youtube/remove_comment_section","userid":"ba656c5622d547659efe36f9","day":741,"synced":0,"timestamp":1515662312889,"localtime":"Thu Jan 11 2018 09:14:13 GMT+0000 (GMT Standard Time)","itemid":"d00d5cdb6e345911194e4c9f","log_major_ver":"8","log_minor_ver":"1","habitlab_version":"1.0.188","id":4,"logname":"youtube/remove_comment_section","timestamp_local":1515662053105}]'
  youtube_remove_comment_dict = json.loads(youtube_remove_comment)
  calibrate_instance(youtube_remove_comment_dict)

  # temporary_disablement()
  # day_vs_session_len()
  # nth_vs_session_len()

if __name__ == "__main__":
  main()